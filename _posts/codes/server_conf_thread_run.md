<script src="https://google-code-prettify.googlecode.com/svn/loader/run_prettify.js?lang=cc&skin=sunburst"></script>
<pre class="prettyprint lang-cc">
void server_conf_thread::run(tbsys::CThread * thread, void *arg)
{
  //根据配置文件中配置的主备CS的IP和本机的IP，来确定当前cs是作为主配置服务器，还是作为备配置服务器；
  uint64_t sync_config_server_id = 0;
  uint64_t tmp_master_config_server_id = master_config_server_id;
  if(tmp_master_config_server_id == util::local_server_ip::ip) {
    tmp_master_config_server_id = get_slave_server_id();
  }
  if(tmp_master_config_server_id)
  //作为备配置服务器在运行
  sync_config_server_id =
    get_master_config_server(tmp_master_config_server_id, 1); 
  if(sync_config_server_id) {
    log_info("syncConfigServer: %s",
        tbsys::CNetUtil::addrToString(sync_config_server_id).
        c_str());
  }
  // 读取group的配置文件名称，这里需要注意的是，在同一个Group中可以配置多个group;
  const char *group_file_name =
    TBSYS_CONFIG.getString(CONFSERVER_SECTION, TAIR_GROUP_FILE, NULL);
  if(group_file_name == NULL) {
    log_error("not found %s:%s ", CONFSERVER_SECTION, TAIR_GROUP_FILE);
    return;
  }
  //将group的配置文件的最后修改时间作为该文件的版本号；
  uint32_t config_version_from_file = get_file_time(group_file_name);
  //bool rebuild_group = true;
  bool rebuild_this_group = false;
  // 这里读取配置文件。对于备配置服务器而言，它需要从主配置服务器中读取配置文件，如果主配置服务器是alive的话；
  load_group_file(group_file_name, config_version_from_file,
      sync_config_server_id);
  //if (syncConfigServer != 0) {
  //    rebuild_group = false;
  //} 
  //当当前机器运行的cs是主配置服务器，或者主配置服务器down掉时，运行以下代码
  //set myself is master
  if(config_server_info_list.size() == 2U &&
      (config_server_info_list[0]->server_id == util::local_server_ip::ip
       || (sync_config_server_id == 0
         && config_server_info_list[1]->server_id ==
         util::local_server_ip::ip))) {
    //running as a master, or not find the master , only the slave.
    master_config_server_id = util::local_server_ip::ip;
    log_info("set MASTER_CONFIG: %s",
        tbsys::CNetUtil::addrToString(master_config_server_id).
        c_str());
    {
      //group info map数据结构在读取配置文件时候建立，具体在load_group_file中完成
      group_info_map::iterator it;
      group_info_rw_locker.rdlock();
      for(it = group_info_map_data.begin();
          it != group_info_map_data.end(); ++it) {
        if(rebuild_this_group) {
          it->second->set_force_rebuild();
        }
        else {
          //通过检查对照表中是否存在0的项，来确定是否需要重建对照表。对照表的建立是以group为单位的，各个group维护自己的对照表；
          bool need_build_it = false;
          const uint64_t *p_table = it->second->get_hash_table();
          log_debug("server_bucket_count: %d", it->second->get_server_bucket_count());
          for(uint32_t i = 0; i < it->second->get_server_bucket_count();
              ++i) {
            if(p_table[i] == 0) {
              need_build_it = true;
              break;
            }
          }
          if(need_build_it) {
            //这里将标记置为1，表示该Group的对照表需要重建
            it->second->set_force_rebuild();
          }
          else {
            it->second->set_table_builded();
          }
        }
      }
      group_info_rw_locker.unlock();
    }
  }
  // will start loop
  uint32_t loop_count = 0;
  tzset();
  int log_rotate_time = (time(NULL) - timezone) % 86400;
  struct timespec tm;
  clock_gettime(CLOCK_MONOTONIC, &tm);
  //记录心跳时间
  heartbeat_curr_time = tm.tv_sec;
  is_ready = true;
  //开始loop
  while(!_stop) {
    struct timespec tm;
    clock_gettime(CLOCK_MONOTONIC, &tm);
    heartbeat_curr_time = tm.tv_sec;
    //检查另外一个cs是否down掉
    for(size_t i = 0; i < config_server_info_list.size(); i++) {
      server_info *server_info_it = config_server_info_list[i];
      if(server_info_it->server_id == util::local_server_ip::ip)
        continue;
      if(server_info_it->status != server_info::ALIVE
          && (loop_count % 30) != 0) {
        down_slave_config_server = server_info_it->server_id;
        log_debug("local server: %s set down slave config server: %s",
            tbsys::CNetUtil::addrToString(util::local_server_ip::ip).c_str(),
            tbsys::CNetUtil::addrToString(down_slave_config_server).c_str());
        continue;
      }
      //向另外一个cs发送心跳包
      down_slave_config_server = 0;
      request_conf_heartbeart *new_packet = new request_conf_heartbeart();
      new_packet->server_id = util::local_server_ip::ip;
      new_packet->loop_count = loop_count;
      if(connmgr_heartbeat->
          sendPacket(server_info_it->server_id, new_packet) == false) {
        delete new_packet;
      }
    }


    loop_count++;
    if(loop_count <= 0)
      loop_count = TAIR_SERVER_DOWNTIME + 1;
    //读取配置文件的版本信息，检查是否需要重新读取配置文件，每次修改配置文件，总会触发CS重新读取配置文件
    uint32_t curver = get_file_time(group_file_name);
    if(curver > config_version_from_file) {
      log_info("groupFile: %s, curver:%d configVersion:%d",
          group_file_name, curver, config_version_from_file);
      //read config from file
      //读取配置文件，第3个参数为0，表示此次只从配置文件读取，不从另外一个CS上读取配置文件
      load_group_file(group_file_name, curver, 0);
      config_version_from_file = curver;
      //作为主CS，将新的配置文件发送到备CS
      send_group_file_packet();
    }
    //检查配置服务器状态
    check_config_server_status(loop_count);
    //检查数据服务器状态
    if(loop_count > TAIR_SERVER_DOWNTIME) {
      check_server_status(loop_count);
    }


    // 日志回滚
    log_rotate_time++;
    if(log_rotate_time % 86400 == 86340) {
      log_info("rotateLog End");
      TBSYS_LOGGER.rotateLog(NULL, "%d");
      log_info("rotateLog start");
    }
    if(log_rotate_time % 3600 == 3000) {
      log_rotate_time = (time(NULL) - timezone) % 86400;
    }
    //休息1s
    TAIR_SLEEP(_stop, 1);
  }
  is_ready = false;
}
</pre>
