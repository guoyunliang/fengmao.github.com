---
title:  字符串比较[TOKU]
layout: post
category: code
---

<script src="https://google-code-prettify.googlecode.com/svn/loader/run_prettify.js?lang=cc&skin=sunburst"></script>
###写在前面

偶然的机会翻看了下TokuDB的字符串比较函数，发现他们实现了好几个版本，不断优化，最终使用优化最好的那个版本。

###代码
在KV系统中，字符串比较函数经常用到，其性能还是非常重要的。看看TokuDB提供的几种字符串比较函数吧。

####版本1

<pre class="prettyprint">
int toku_keycompare (bytevec key1, ITEMLEN key1len, bytevec key2, ITEMLEN key2len)
{
  if (key1len==key2len)
  {
    return memcmp(key1,key2,key1len);
  } 
  else if (key1len < key2len)
  {
    int r = memcmp(key1,key2,key1len);
    if (r<=0) return -1; /* If the keys are the same up to 1's length, then return -1, since key1 is shorter than key2. */
    else return 1;
  }
  else
  {
    return -toku_keycompare(key2,key2len,key1,key1len);
  }
}
</pre>


这个版本比较简单，使用memcmp函数，并且使用了递归的算法。逻辑清晰，没有什么好说的。

####版本2

<pre class="prettyprint">
int toku_keycompare (bytevec key1, ITEMLEN key1len, bytevec key2, ITEMLEN key2len)
{
  if (key1len==key2len)
  {
    return memcmp(key1,key2,key1len);
  }
  else if (key1len < key2len)
  {
    int r = memcmp(key1,key2,key1len);
    if (r<=0) return -1; 
    //If the keys are the same up to 1's length, then return -1, since key1 is shorter than key2.
    else return 1;
  }
  else
  {
    int r = memcmp(key1,key2,key2len);
    if (r>=0) return 1; 
    // If the keys are the same up to 2's length, then return 1 since key1 is longer than key2.
    else return -1;
  }
}
</pre>

相比版本1，版本2去掉了递归调用，全部使用memcmp实现。


####版本3

<pre class="prettyprint">
int toku_keycompare (bytevec key1, ITEMLEN key1len, bytevec key2, ITEMLEN key2len) 
{
  int comparelen = key1len<key2len ? key1len : key2len;
  const unsigned char *k1;
  const unsigned char *k2;
  
  for (k1=key1, k2=key2; comparelen>0; k1++, k2++, comparelen--)
  {
    if (*k1 != *k2)
    {
      return (int)*k1-(int)*k2;
    }
  }

  if (key1len<key2len) return -1;
  if (key1len>key2len) return 1;
  return 0;
}
</pre>

这个版本进一步优化，去掉对memcmp调用，直接循环比较每一个字符。


####版本4

<pre class="prettyprint">
int toku_keycompare (bytevec key1, ITEMLEN key1len, bytevec key2, ITEMLEN key2len)
{
  int comparelen = key1len<key2len ? key1len : key2len;
  const unsigned char *k1;
  const unsigned char *k2;

  for (CAST_FROM_VOIDP(k1, key1), CAST_FROM_VOIDP(k2, key2); comparelen > 4; k1+=4, k2+=4, comparelen-=4)
  {
    { int v1=k1[0], v2=k2[0]; if (v1!=v2) return v1-v2; }
    { int v1=k1[1], v2=k2[1]; if (v1!=v2) return v1-v2; }
    { int v1=k1[2], v2=k2[2]; if (v1!=v2) return v1-v2; }
    { int v1=k1[3], v2=k2[3]; if (v1!=v2) return v1-v2; }
  }

  for (;  comparelen>0; k1++, k2++, comparelen--)
  {
    if (*k1 != *k2) 
    {
      return (int)*k1-(int)*k2;
    }
  }
  if (key1len<key2len) return -1;
  if (key1len>key2len) return 1;
  return 0;
}
</pre>

版本3每次比较一个字符，版本4在其基础上再次优化，每次比较4个字节。想想为什么要这样优化吧？


###实验结果

我简单的写了个对比实验，产生10,000,000个随机字符串，长度为64。分别运行上述4中字符串比较函数10,000,000次，求得总的运行时间，并且除以总的调用次数，得出每次调用比较函数需要的时间（单位ms)。我的测试机器的配置为Intel(R) Xeon(R) CPU E5520  @ 2.27GHz, 16 cores, 内存24G，g++版本 > 4.0.0。测试结果如下：

<p align=center><img src=/images/2013-05-24/r.jpg width=438></p>

上述数据表示，每个版本执行10,000,000后，求得一次调用的平均时间，单位是ms。
通过上述看出，字符串比较函数优化还是很明显的，版本3和4明显比版本2和1要节约时间，同时版本4用时最少。



