<?php


// (c) 2013 Labgency, Inc. All rights reserved


// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


$___errno = 0;

function  errno_set ($errno)
{
  global $___errno;
  $___errno = $errno;
}

function  errno_get ()
{
  global $___errno;
  return  $___errno;
}

function  errno ()
{
  return  errno_get();
}


$___errmsg = "";

function  errmsg_set ($errmsg)
{
  global $___errmsg;
  $___errmsg = $errmsg;
}

function  errmsg_get ()
{
  global $___errmsg;
  return  $___errmsg;
}

function  errmsg ()
{
  return  errmsg_get();
}



$___status = 0;

function  status_set ($status)
{
  global $___status;
  $___status = $status;
}


function  status ()
{
  global $___status;
  return  $___status;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// EOF!

