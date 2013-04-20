---
title: 【linux file system 相关】
layout: post
category: linux
---
<p>  just test, insert code. </p>
![alt main](/images/codes/123.png "MAIN")

<p> insert code </p>

```
void sign_handler(int sig)
{
  switch (sig) {
    case SIGTERM:
    case SIGINT:
      if (tair_server != NULL) {
        log_info("will stop tairserver");
        tair_server->stop();
      }   
      break;
    case 40: 
      TBSYS_LOGGER.checkFile();
      break;
    case 41: 
    case 42: 
      if (sig==41) {
        TBSYS_LOGGER._level ++; 
      } else {
        TBSYS_LOGGER._level --; 
      }   
      log_error("TBSYS_LOGGER._level: %d", TBSYS_LOGGER._level);
      break;
    case 43: 
  }
}
```
