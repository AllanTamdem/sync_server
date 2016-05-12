<?php


// (c) 2013 Labgency, Inc. All rights reserved


/*

LGYHSS(3)        Labgency Hedgehog Security Library Manual

NAME
	hss-client.inc.php -- a set of functions implementing HSP
	transactions.

	lgyhss_request -- forge a valid HSS/ASR client request
	lgyhss_request2 -- forge a valid HSS/ASR client request

	lgy_catalog -- returns list of catalog entries
	lgy_token -- create a new playback token

SYNOPSIS
	function lgyhss_request($aid,$key,$ivkw,$sigkw,$query,$body,$url,$port);

DESCRIPTION
	Transactions to the Labgency platform are secured with the Hedgehog
	Security Protocol. It consists in authenticating and identifying
	incoming requests with shared keys.

	A valid request is signed and encrypted following shared values
	between the client and the server. The shared values, e.g. keys
	and keywords are in a UUID form, meaning a 36 characters long
	string of 32 hexadecimal characters separated by hyphens.

	Two functions will address low level transactions:
	 -  lgyhss_request()
	 -  lgyhss_request2()

	lgyhss_request() will take regular HTTP GET or POST arguments with the
	clear query string, the clear body, then forge and send a valid HSS/ASR
	request.

	lgyhss_request2() is similar to lgyhss_request() but allows finer
	arguments. Rather than only returning the body of the reply, it
	returns the status code.

	Two functions implement playabck specific transactions:
	 -  lgy_catalog()
	 -  lgy_token()

	lgy_catalog() returns a list of lines. Each line is itself
	an associative array. Each line has a "cid" item. "cid"
	stands for "Content ID".

	lgy_token() will create a playback token. One argument is
	one valid "cid" earlier found using lgy_catalog().

	This package requires the mcrypt extension.

RETURN VALUES
	lgyhss_request() returns the body of the HTTPS reply.
	lgyhss_request2() returns the response status.

EXAMPLES
	$aid = 'DD1F83B2-2D69-11E4-B138-BFF8A075EFAB';
	$key = 'DE5352AE-2D69-11E4-ABDE-BBBA73F29506';
	$sigkw = 'DF86F2DE-2D69-11E4-A786-5B6E521C261A';
	$ivkw = 'E0BA8BDE-2D69-11E4-80C0-77497C6E79C6';
	
	$url = "https://api.labgency.ws/play/asr";
	$port = 443;
	
	$query = "test=value";
	$body = "test body";
	
	$data = lgyhss_request($aid,$key,$ivkw,$sigkw,$query,$body,$url,$port);

SEE ALSO
	Labgency Hedgehog Security System documentation

FILES
	/etc/lgyhostname
	/etc/lgydomain
	/var/lib/lgy/csc/lgy-hss/aid.cfg

BUGS
	to be completed

NOTICE
	UNPUBLISHED This product contains unpublished confidential information and 
	is not to be disclosed or used except as authorized by written contract or 
	agreement with Labgency.

*/



// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

require_once("constant.inc.php");
require_once("fctn.inc.php");
require_once("errno.inc.php");

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// global


// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


function  splitkeyvalue ($s, &$key, &$value, $csep)
{
  $key = '';
  $value = '';
  $sep = strpos($s,$csep,0);
  if ( $sep === false )  $sep = strlen($s);
  $key = trim(substr($s,0,$sep));
  if ( $sep < strlen($s) )
    $value = trim(substr($s,$sep+1));
  return 0;
}  // end fctn



// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function  lgyhss_signature1 ($sigkw,$salt,$query,$body)
{
  $res = "";
  $sigkw = strtoupper($sigkw);
  $sigref = format_uuid(sha1($sigkw.$salt.$query.$body));
  return $sigref;
}  // end fctn


function  lgyhss_iv ($sigkw,$salt)
{
  $res = "";
  $sigkw = strtoupper($sigkw);
  $sigref = format_uuid(sha1($sigkw.$salt));
  return $sigref;
}  // end fctn


function  lgyhss_signature ($sigkw,$salt,$query,$body)
{
  $res = "";
  $sigkw = strtoupper($sigkw);
  $sigref = format_euuid(sha1($sigkw.$salt.$query.$body));
  return $sigref;
}  // end fctn


function  lgyhss_a ($sigkw,$salt)
{
  $sigkw = strtoupper($sigkw);
  $sigref = format_euuid(sha1($sigkw.$salt));
  return $sigref;
}  // end fctn


function  lgyhss_salt ()
{
  $tnow = time();
  //$now = date('U',$tnow);
  return $tnow;
}  // end fctn


function  lgyhss_forge_request ($aid,$key,$ivkw,$sigkw,$salt,&$header,&$query,&$body)
{
  if ( ! isset($header) )  $header = array();
  $header[] = 'X-Lgy-Hss-Aid: '.$aid;
  $header[] = 'X-Lgy-Hss-Salt: '.$salt;
  $iv = lgyhss_iv($ivkw,$salt);
  if ( strlen($query) > 0 )  $query = encrypt($key,$iv,$query);
  if ( strlen($body) > 0 )  $body = encrypt($key,$iv,$body);
  $sigref = lgyhss_signature($sigkw,$salt,$query,$body);
  $header[] = 'X-Lgy-Hss-Signature: '.$sigref;
}  // end fctn




// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


// ----
// client side functions


/**
  lgyhss_request() will create a valid API request, send the request and
  return the response body. This function is for client application
  servers.

  @return string: the body from the HTTP response
  @param aid: string: application/portal identifier in a UUID format
  @param key: string: the 128bits encryption key in a UUID format
  @param ivkw: string: a keyword used to generate the AES IV, in UUID format
  @param sigkw: string: a keyword used to generate the request signature, in UUID format
  @param a_query: string: the query string
  @param a_body: string: the post data, an empty string would mean a GET request only
  @param url: string: the system url (like 'https://api/enabler')
  @param port: int: the system port (like 443)
 */
function  lgyhss_request ($aid,$key,$ivkw,$sigkw,$a_query,$a_body,$url,$port,$header=null,$returnheaders=0)
{
  $attempt_n = 3;
  $salt = lgyhss_salt();
  if ( $header == null )  $header = array();
  $query = $a_query;
  $body = $a_body;
  lgyhss_forge_request($aid,$key,$ivkw,$sigkw,$salt,$header,$query,$body);
  $url = $url."?".$query;
  $curl = curl_init();
  curl_setopt($curl, CURLOPT_URL, $url);
  curl_setopt($curl, CURLOPT_PORT, $port);
  curl_setopt($curl, CURLOPT_VERBOSE, 0);
  curl_setopt($curl, CURLOPT_HEADER, $returnheaders);
  // curl_setopt($curl, CURLOPT_SSLVERSION, 3);
  // curl_setopt($curl, CURLOPT_SSLCERT, getcwd() . "/client.pem");
  // curl_setopt($curl, CURLOPT_SSLKEY, getcwd() . "/keyout.pem");
  // curl_setopt($curl, CURLOPT_CAINFO, getcwd() . "/ca.pem");
  curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0); // necessary
  curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, 0); // necessary
  curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
  curl_setopt($curl, CURLOPT_MAXREDIRS, 20);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($curl, CURLOPT_HTTPHEADER,$header);
  if ( strlen($body) > 0 )
  {
    // curl_setopt($curl, CURLOPT_POSTREDIR, 3); // not ok on most PHP versions
    curl_setopt($curl, CURLOPT_POST, 1);
    curl_setopt($curl, CURLOPT_POSTFIELDS,$body);
  }
  for ( $i = 0 ; $i < $attempt_n ; $i++ )
  {
    //error_log("curl: ".$i.": ".$url);
    $data = curl_exec($curl);
    if ( curl_errno($curl) == 0 )  break;
    //else  error_log("curl failed: ".curl_errno($curl).": ".curl_error($curl));
  }
  curl_close($curl);
  return $data;
}  // end fctn



class  lgyhss_request_curl
{
  public  $header = "";
  public  $body = "";
  public  $use_stdout = false;

  function curl_header_callback($ch, $data)
  {
    $this->header .= $data;
    return strlen($data);
  }

  function curl_body_callback($ch, $data)
  {
    if ( ! $this->use_stdout )  $this->body .= $data;
    else  print($data);
    return strlen($data);
  }

};  // end class


function  lgyhss_request2 ($aid,$key,$ivkw,$sigkw,$a_query,$a_body,$url,$port,&$replybody,&$replyheader,$header=null,$use_stdout=false)
{
  $status = 0;
  $attempt_n = 3;
  $salt = lgyhss_salt();
  if ( $header == null )  $header = array();
  $query = $a_query;
  $body = $a_body;
  lgyhss_forge_request($aid,$key,$ivkw,$sigkw,$salt,$header,$query,$body);
  $url = $url."?".$query;
  $curl = curl_init();
  $replyheader = "";
  $replybody = "";
  curl_setopt($curl, CURLOPT_URL, $url);
  curl_setopt($curl, CURLOPT_PORT, $port);
  curl_setopt($curl, CURLOPT_VERBOSE, 0);
  curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0); // necessary
  curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, 0); // necessary
  curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
  curl_setopt($curl, CURLOPT_MAXREDIRS, 20);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($curl, CURLOPT_HTTPHEADER,$header);
  curl_setopt($curl, CURLOPT_FRESH_CONNECT, 1);
  curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);
  curl_setopt($curl, CURLOPT_TIMEOUT, 10);
  if ( strlen($body) > 0 )
  {
    // curl_setopt($curl, CURLOPT_POSTREDIR, 3); // not ok on most PHP versions
    curl_setopt($curl, CURLOPT_POST, 1);
    curl_setopt($curl, CURLOPT_POSTFIELDS,$body);
  }
  curl_setopt($curl, CURLOPT_HEADER, 0);
  $lrc = new lgyhss_request_curl;
  $lrc->header = "";
  $lrc->body = "";
  $lrc->use_stdout = $use_stdout;
  curl_setopt($curl,CURLOPT_HEADERFUNCTION,array($lrc, 'curl_header_callback'));
  curl_setopt($curl,CURLOPT_WRITEFUNCTION,array($lrc, 'curl_body_callback'));
  for ( $i = 0 ; $i < $attempt_n ; $i++ )
  {
    $r = curl_exec($curl);
    if( curl_errno($curl) == 0 )  break;
  }
  if ( curl_errno($curl) != 0 )
  {
    errmsg_set("lgyhss_request2: connection failed: ".$url." (".$port.") ".$aid);
    errno_set(E_HSS_REPLY_CONNECTION_FAILED);
    return E_HSS_REPLY_CONNECTION_FAILED;
  }
  $replyheader = $lrc->header;
  $replybody = $lrc->body;
  //error_log($replyheader);
  if ( $replyheader )
  {
    if( preg_match( "/X-Lgy-Hss-Status: (\d+)/i", $replyheader, $matches ) )
      $status = (int) $matches[1];
    if( preg_match( "/X-Lgy-Status: (\d+)/i", $replyheader, $matches ) )
      $status = (int) $matches[1];
  }
  else
  {
    errmsg_set("lgyhss_request2: empty headers");
    errno_set(E_HSS_REPLY_EMPTY_HEADER);
    return E_HSS_REPLY_EMPTY_HEADER;
  }
  // curl_setopt($curl, CURLOPT_CUSTOMREQUEST, 'GET');
  // if ( strlen($body) > 0 )  curl_setopt($curl, CURLOPT_CUSTOMREQUEST, 'POST');
  // curl_setopt($curl, CURLOPT_HEADER, 0);
  // curl_setopt($curl, CURLOPT_NOBODY, 0);
  curl_close($curl);
  return $status;
}  // end fctn



// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


function  lgy_catalog ($aid,$key,$ivkw,$sigkw,$url,$port,$service_id,$version=9999)
{
  $csvsep = ";";
  $body = "";
  $query = "e=play&m=catalog&s=".$service_id."&version=".$version;
  $data = lgyhss_request($aid,$key,$ivkw,$sigkw,$query,$body,$url,$port);
  //print($data."\n");
  
  $reply = explode("\n",$data);
  if ( trim($reply[0]) != "ok" )  { print("ERROR\n");  exit(1); }
  
  $catalog0 = array_slice($reply,1,count($reply)-1);
  $catalog1 = "";
  foreach ( $catalog0 as $l )  $catalog1 .= $l."\n";
  $catalog = csv_parse($catalog1,$csvsep,0,-1);
  return $catalog;
}  // end fctn


function  lgy_token ($aid,$key,$ivkw,$sigkw,$url,$port,$service_id,$cid,$session)
{
  $prop = http_build_query($session);
  $query = "e=play&m=token&s=".$service_id."&c=".$cid."&".$prop;
  $body = "";
  $data = lgyhss_request($aid,$key,$ivkw,$sigkw,$query,$body,$url,$port);
  //print($data."\n");
  $reply = explode("\n",$data);
  if ( trim($reply[0]) != "ok" )  { print("ERROR\n".$data);  exit(1); }
  $token = $reply[1];
  return $token;
}  // end fctn




// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// sample

/*
// param

// the following are strings shared with the server side
// aid is the application/portal identifier, it will be sent in clear
// and will enable to link to all the other shared keys: key, sigkw,
// ivkw.
//
// one AID is mapped to one service identifier on the platform.
//


$cfg = "DD1F83B2-2D69-11E4-B138-BFF8A075EFAB,DE5352AE-2D69-11E4-ABDE-BBBA73F29506,DF86F2DE-2D69-11E4-A786-5B6E521C261A,E0BA8BDE-2D69-11E4-80C0-77497C6E79C6,test";
$cfgv = explode(",",$cfg);
$aid = $cfgv[0];
$key = $cfgv[1];
$ivkw = $cfgv[2];
$sigkw = $cfgv[3];

$port = 443;



echo "\n\n**** encryption/decryption basic test ****\n\n";

$iv = $key;
$e_msg = encrypt($key,$iv,"hey buddy");
$d_msg = decrypt($key,$iv,$e_msg);
print("'".$d_msg."'\n");



echo "\n\n**** test a proxy request ****\n\n";

$url = "https://api.labgency.ws/testproxy";
$query = "test=cool";
$body = "test body";
// lgyhss_request() will create a valid request and send it.
$data = lgyhss_request($aid,$key,$ivkw,$sigkw,$query,$body,$url,$port);
print($data."\n");



echo "\n\n**** test a simple identified service request ****\n\n";

$url = "https://api.labgency.ws/testasr";
$query = "test=cool";
$body = "test body";
// lgyhss_request() will create a valid request and send it.
$data = lgyhss_request($aid,$key,$ivkw,$sigkw,$query,$body,$url,$port);
print($data."\n");



*/



// EOF!

