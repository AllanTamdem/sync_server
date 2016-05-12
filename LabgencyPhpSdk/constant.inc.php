<?php

// (c) 2013 Labgency, Inc. All rights reserved

/*
	 -  1: HSS error: invalid AID format
	 -  2: HSS error: invalid signature format
	 -  3: HSS error: salt is not within range
*/
ini_set('display_errors',1);
ini_set('display_startup_errors',1);
error_reporting(-1);
define("OK",0);

// HSS Error Codes (errno)
define("E_HSS_AID_INVALID_FORMAT",1); 
define("E_HSS_A_UNKNOWN",2);
define("E_HSS_PASSWORD_INVALID",3);
define("E_HSS_AID_INVALID_VALUE",4);
define("E_HSS_SIGNATURE_INVALID_VALUE",5);
define("E_HSS_DEVICEID_MISSING",6);
define("E_HSS_A_INVALID_VALUE",7);
define("E_HSS_INITIAL_FLAG_MISSING",8);
define("E_HSS_ROMID_MISSING",9);
define("E_HSS_VERSION_MISSING",10);
define("E_HSS_SIGNATURE_INVALID_FORMAT",11); 
define("E_HSS_SALT_INVALID",12);
define("E_HSS_REPLY_EMPTY_HEADER",14);
define("E_HSS_REPLY_CONNECTION_FAILED",15);
define("E_HSS_SERVICE_INVALID",16);

// DATA Error Codes
define("E_DATA_ERROR",100);
define("E_DATA_UPDATE_VALUE_FAILED",101);
define("E_DATA_GET_VALUELIST_FAILED",102);
define("E_DATA_DELETE_LOCATION_FAILED",103);
define("E_DATA_ADD_LOCATION_FAILED",104);

// DATA SDK Error Codes
define("E_DATASDK_DELETE_FAILED",110);
define("E_DATASDK_FILEOPEN_FAILED",111);

// TABLE Error Codes
define("E_TABLE_WRONGARG",120);
define("E_TABLE_FILENOTFOUND",121);
define("E_TABLE_UNKNOWNCOMMAND",122);

// EOF!

