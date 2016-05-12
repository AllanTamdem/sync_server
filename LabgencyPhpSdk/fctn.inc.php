<?php

// (c) 2013 Labgency, Inc. All rights reserved


function  uniqueid ()
{
  $stamp = date("Ymdhis");
  $c = uniqid(rand(), true);
  return $stamp."-".$c;
}  // end fctn


function  deriveid ($name)
{
  $r = "";
  for ( $i = 0 ; $i < strlen($name) ; $i++ )
  {
    $c = substr($name,$i,1);
    if ( ( ord($c) >= ord("0") ) && ( ord($c) <= ord("9") ) )  $r .= $c;
    if ( ( ord($c) >= ord("A") ) && ( ord($c) <= ord("Z") ) )  $r .= $c;
    if ( ( ord($c) >= ord("a") ) && ( ord($c) <= ord("z") ) )  $r .= $c;
  }  // end for
  return $r;
}  // end fctn


function microtime_float ()
{
  list($usec, $sec) = explode(" ", microtime());
  return ((float)$usec + (float)$sec);
}

/**
 @param p: array of 4 double values: of the x interval
 @param x: double value, at which to calculate the interpolated value
 @return a double value, interpolated at the x coordinate
 */

function cubicinterpolate ($p, $x)
{
  // double  p [4];
  // double  x;
  return $p[1] + 0.5 * $x *($p[2] - $p[0] + $x * (2.0*$p[0] - 5.0*$p[1] + 4.0*$p[2] - $p[3] + $x*(3.0*($p[1] - $p[2]) + $p[3] - $p[0])));
}  // end fctn


function  num_separated ($nbr)
{
  $b =  "" . $nbr;
  $r = "";
  $l = 0;
  for ( $k = (strlen($b) - 1) ; $k >= 0 ; $k-- )
  {
    $c = substr($b,$k,1);
    if ( $c != "-" )
    {
      if ( $l == 3 )  { $r = "," . $r;  $l = 0; }
      $r = $c . $r;
      $l++;
    }
  }
  //if ( $c == "-" )  $r = "(" . $r . ")";
  return $r;
}  // end fctn


function  strfind ($str,$search,$offset)
{
  $p = strpos($str,$search,$offset);
  if ( $p === false )  return strlen($str);
  return $p;
}  // end fctn


function  splitkv ($s,$sep,$offset = 0)
{
  $r = array();
  $idx = strfind($s,$sep,$offset);
  $r[0] = substr($s,0,$idx);
  $r[1] = "";
  //if ( $idx < strlen($s) )  $r[1] = substr($s,$idx+strlen(sep));
  if ( $idx < strlen($s) )  $r[1] = substr($s,$idx+1);
  return  $r;
}  // end fctn


function  splitkv_left ($s,$sep,$offset = 0)
{
  $r = splitkv($s,$sep,$offset);
  return  $r[0];
}  // end fctn


function  splitkv_right ($s,$sep,$offset = 0)
{
  $r = splitkv($s,$sep,$offset);
  return  $r[1];
}  // end fctn


function  print_query ($dbl,$query)
{
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die( "mysql error: " . mysql_error() );

  $fw = array();
  while ($record = mysql_fetch_array($r, MYSQL_NUM))
  {
    // printf("ID: %s  Name: %s", $row[0], $row[1]);
    for ( $i = 0 ; $i < count($record) ; $i++ )
    {
      if ( ! isset($fw[$i]) )  $fw[$i] = 0;
      if ( strlen($record[$i]) > $fw[$i] )  $fw[$i] = strlen(htmlspecialchars_decode($record[$i]));
    }
  }

  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");

  $record = array();
  for ( $i = 0 ; $i < mysql_num_fields($r) ; $i++ )
  {
    $record[] = mysql_fetch_field($r,$i)->name;
  }  // end for
  for ( $i = 0 ; $i < count($record) ; $i++ )
  {
    if ( strlen($record[$i]) > $fw[$i] )  $fw[$i] = strlen(($record[$i]));
    if ( $i == 0 )  printf("\t | ");
    printf("%-".$fw[$i]."s",$record[$i]);
    printf(" | ");
  }
  printf("\n");

  while ($record = mysql_fetch_array($r, MYSQL_NUM))
  {
    // printf("ID: %s  Name: %s", $row[0], $row[1]);
    for ( $i = 0 ; $i < count($record) ; $i++ )
    {
      if ( $i == 0 )  printf("\t | ");
      printf("%-".$fw[$i]."s",$record[$i]);
      printf(" | ");
    }
    printf("\n");
  }
  mysql_free_result($r);
}  // end fctn


function  print_query_table ($dbl,$query,$id="")
{
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");

  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");

  $tag = "<table ";
  if ( $id != "" )  $tag .= "id=\"".$id."\"";
  $tag .= " >";

  print($tag."\n");

  $record = array();
  for ( $i = 0 ; $i < mysql_num_fields($r) ; $i++ )
  {
    $record[] = mysql_fetch_field($r,$i)->name;
  }  // end for
  print("<thead>\n");
  print("<tr>\n");
  for ( $i = 0 ; $i < count($record) ; $i++ )
  {
    print("<th>\n");    
    print($record[$i]);
    print("</th>\n");
  }
  print("</tr>\n");
  print("</thead>\n");
  printf("\n");


  print("<tbody>\n");
  while ($record = mysql_fetch_array($r, MYSQL_NUM))
  {
    // printf("ID: %s  Name: %s", $row[0], $row[1]);
    print("<tr>\n");
    for ( $i = 0 ; $i < count($record) ; $i++ )
    {
      print("<td>\n");    
      print($record[$i]);
      print("</td>\n");
    }
    print("</tr>\n");
    printf("\n");
  }

  print("</tbody>\n");
  print("</table>\n");

  mysql_free_result($r);
}  // end fctn


function  print_table ($head,$table,$link,$id="")
{
  $tag = "<table ";
  if ( $id != "" )  $tag .= "id=\"".$id."\"";
  $tag .= " >";

  print($tag."\n");

  print("<thead>\n");
  print("<tr>\n");
  for ( $i = 0 ; $i < count($head) ; $i++ )
  {
    print("<th>\n");    
    print($head[$i]);
    print("</th>\n");
  }
  print("</tr>\n");
  print("</thead>\n");
  printf("\n");


  print("<tbody>\n");
  for ( $i = 0;$i<count($table);$i++ )
  {
    $record = $table[$i];
    // printf("ID: %s  Name: %s", $row[0], $row[1]);
    print("<tr>\n");
    $href = "";
    if ( $link != null )
      if ( isset($link[$i]) )
        $href = $link[$i];
    if ( $href != "" )  print("<a href=\"".$href."\" >\n");
    for ( $j = 0 ; $j < count($record) ; $j++ )
    {
      print("<td>\n");    
      print($record[$j]);
      print("</td>\n");
    }
    if ( $href != "" )  print("</a>\n");
    print("</tr>\n");
    printf("\n");
  }

  print("</tbody>\n");
  print("</table>\n");
}  // end fctn



function  print_table_csv ($head,$table,$sep=";",$quote="\"",$eol="\015\012")
{

  for ( $i = 0 ; $i < count($head) ; $i++ )
  {
    if ( $i > 0 )  print($sep);
    $value = $head[$i];
    if ( strfind($value,"\"",0) < strlen($value) )
    {
      $value = str_replace("\"","\"\"",$record[$j]);
      $value = $quote.$value.$quote;
    }
    print($value);
  }
  printf($eol);

  for ( $i = 0 ; $i<count($table) ; $i++ )
  {
    $record = array_values($table[$i]);
    for ( $j = 0 ; $j < count($record) ; $j++ )
    {
      if ( $j > 0 )  print($sep);
      $value = $record[$j];
      if ( strfind($value,"\"",0) < strlen($value) )
      {
        $value = str_replace("\"","\"\"",$record[$j]);
        $value = $quote.$value.$quote;
      }
      print($value);
    }
    printf($eol);
  }
}  // end fctn



function  csv_parse ($catalog_csv,$csvsep,$offset,$limit)
{
  $result = array();
  $entry = array();

  //$catalog = file($f_catalog);
  $eol = "\012";
  if ( strfind($catalog_csv,"\015\012",0) < strlen($catalog_csv) )  $eol = "\015\012";
  $catalog = explode($eol,$catalog_csv);
  $header = array();
  if ( count($catalog) > 0 )  $header = str_getcsv($catalog[0],$csvsep);

  $n = 0;
  $m = -1;
  for ( $i = 1 ; $i < count($catalog) ; $i++ )
  {
    $l = $catalog[$i];
    $l = trim($l);
    if ( $l == "ok" )  continue;
    if ( strlen($l) == 0 )  continue;
    $first = ($i==0);
    $m++;
    if ( ! $first )  if ( $m < $offset )  continue;
    $line = str_getcsv($l,$csvsep);
    $entry = array();
    // WAS: for ( $j = 0 ; $j < count($line) ; $j++ )
    for ( $j = 0 ; $j < count($header) ; $j++ )
      $entry[$header[$j]] = arraygetstr($line,$j);
    if ( ! $first )  $result[] = $entry;
    if ( ! $first )  $n++;
    if ( ($limit >= 0) && ($n >= $limit) )  break;
  }  // end foreach
  return  $result;
}  // end fctn



function  csv_load ($f_catalog,$csvsep,$offset,$limit)
{
  if ( ! file_exists($f_catalog) )  return array();
  $catalog_csv = file_get_contents($f_catalog);
  return  csv_parse($catalog_csv,$csvsep,$offset,$limit);
}  // end fctn



function  mysql_exec_simple2 ($dbl,$query)
{
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");
  //mysql_free_result($r);
}  // end fctn


function  mysql_exec_get_single2 ($dbl,$query,&$table)
{
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");
  $table = array();
  while ($record = mysql_fetch_array($r, MYSQL_NUM))
  {
    $table[] = $record[0];
  }
  mysql_free_result($r);
}  // end fctn


function  mysql_exec_get_single3 ($dbl,$query)
{
  $table = array();
  mysql_exec_get_single2($dbl,$query,$table);
  return  $table;
}  // end fctn


function  mysql_exec_count_records2 ($dbl,$query)
{
  $n = 0;
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");
  while ($record = mysql_fetch_array($r, MYSQL_NUM))  $n++;
  mysql_free_result($r);
  return  $n;
}  // end fctn


function  mysql_exec_get_string2 ($dbl,$query,&$str)
{
  $str = "";
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");
  while ($record = mysql_fetch_array($r, MYSQL_NUM))
  {
    $str = $record[0];
    break;
  }
  mysql_free_result($r);
}  // end fctn


function  mysql_exec_get_string3 ($dbl,$query,&$str)
{
  $str = "";
  mysql_exec_get_string2($dbl,$query,$str);
  return $str;
}  // end fctn


function  mysql_exec_get2 ($dbl,$query,&$table)
{
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");
  $table = array();
  while ($record = mysql_fetch_array($r, MYSQL_NUM))
  {
    $table[] = $record;
  }
  mysql_free_result($r);
}  // end fctn


function  query_to_table ($dbl,$query,&$head,&$table)
{
  $r = mysql_query($query,$dbl);
  if ( ! $r )  die("mysql error: ".mysql_error()."  for '".$query."' ");
  $record = array();
  for ( $i = 0 ; $i < mysql_num_fields($r) ; $i++ )
  {
    $record[] = mysql_fetch_field($r,$i)->name;
  }  // end for
  $head = $record;
  $table = array();
  while ($record = mysql_fetch_array($r, MYSQL_NUM))
  {
    $table[] = $record;
  }
  mysql_free_result($r);
}  // end fctn


function  print_query_table_alt ($dbl,$query,$id="")
{
  $head = null;
  $table = null;
  query_to_table($dbl,$query,$head,$table);
  print_table($head,$table,null,$id);
}  // end fctn


function  mysql_insert_into ($dbl,$tbl,$rec)
{
  $q = "insert into ".$tbl." (";
  $k = array_keys($rec);
  $v = array_values($rec);
  for ( $i = 0 ; $i < count($k) ; $i++ )
  {
    if ( $i > 0 )  $q .= ",";
    $q .= "`".$k[$i]."`";
  }
  $q .= ") VALUES (";
  for ( $i = 0 ; $i < count($v) ; $i++ )
  {
    if ( $i > 0 )  $q .= ",";
    $q .= "'".addslashes($v[$i])."'";
  }
  $q .= ");";
  mysql_exec_simple2($dbl,$q);
}  // end fctn


function  arrayelt ($array, $elt)
{
  $r = "";
  if ( isset($array) )
    if ( isset($array[$elt]) )
      $r = $array[$elt];
  return $r;
}  // end fctn


function  kv_set ($dbl,$t,$k,$v)
{
  $k = mysql_real_escape_string($k);
  $v = mysql_real_escape_string($v);
  $q = "select `k` from `".$t."` where `k` = '".$k."'; ";
  $x = "";
  $tnow = time();
  $now = date('U',$tnow);
  mysql_exec_get_string2($dbl,$q,$x);
  if ( $x == $k )
  {
    $q = "update `".$t."` set `v` = '".$v."',`s` = '".$now."' where `k` = '".$k."'; ";
    mysql_exec_simple2($dbl,$q);
  }
  else
  {
    $q = "insert into `".$t."` (`k`,`v`,`s`) VALUES ('".$k."','".$v."','".$now."'); ";
    mysql_exec_simple2($dbl,$q);
  }
}  // end fctn


function  kv_get ($dbl,$t,$k)
{
  $k = mysql_real_escape_string($k);
  $v = "";
  $q = "select `v` from `".$t."` where `k` = '".$k."'; ";
  mysql_exec_get_string2($dbl,$q,$v);
  return  $v;
}  // end fctn


function  kv_del ($dbl,$t,$k)
{
  $k = mysql_real_escape_string($k);
  $q = "delete from `".$t."` where `k` = '".$k."'; ";
  mysql_exec_simple2($dbl,$q);
  return 0;
}  // end fctn


function  kv_lock ($dbl,$table,$k)
{
  $now = time();
  $locktimeout = 180; // 3min
  $locktry = 3;
  for ( $try = 0 ; $try < $locktry ; $try++ )
  {
    for ( $tryb = 0 ; $tryb < $locktry ; $tryb++ )
    {
      $locked = kv_get($dbl,$table,$k);
      if ( $locked == "" )  break;
      if ( $locked == "0" )  break;
      if ( ( $now - $locked ) > $locktimeout )  break;
    }
    kv_set($dbl,$table,$k,$now);  // lock
    usleep(10000);
    $locked = kv_get($dbl,$table,$k);
    if ( $locked == $now )  return 0;
  }
  return 1;
}  // end fctn


function  kv_unlock ($dbl,$table,$k)
{
  kv_del($dbl,$table,$k);
  return 0;
}  // end fctn


function  authenticate ()
{
  $htaccess_user = "";
  $htaccess_pw = "";
  // windows server
  if ( isset($_SERVER["HTTP_HTACCESS_USER"]) ) $htaccess_user = $_SERVER["HTTP_HTACCESS_USER"];
  if ( isset($_SERVER["HTTP_HTACCESS_PASSWORD"]) ) $htaccess_pw = $_SERVER["HTTP_HTACCESS_PASSWORD"];
  // Linux server
  if ( isset($_SERVER["PHP_AUTH_USER"]) ) $htaccess_user = $_SERVER["PHP_AUTH_USER"];
  if ( isset($_SERVER["PHP_AUTH_PW"]) ) $htaccess_pw = $_SERVER["PHP_AUTH_PW"];
  if ( strlen($htaccess_user) == 0 )  { header("WWW-Authenticate: Basic realm=\"Restricted Access\"");  return(0); }
  $cleared = false;
  // if ( ( $htaccess_user == "***USER***" ) && ( $htaccess_pw == "***PASSWORD***" ) )  $cleared = true;
  if ( ! $cleared )  {  print("invalid access\n");  return(0);  }
  return 0;
}  // end fctn


function  arrayget ($array,$elt)
{
  $r = NULL;
  if ( isset($array) )
    if ( isset($array[$elt]) )
      $r = $array[$elt];
  return  $r;
}  // end fctn


function  arraygetstr ($array, $elt)
{
  $r = arrayget($array,$elt);
  if ( $r == NULL )  $r = "";
  return $r;
}  // end fctn


function  filterinjection ($s)
{
  str_replace(";","",$s);
  str_replace("--","",$s);
  str_replace("'","\\'",$s);
  str_replace("\"","\\\"",$s);
  return $s;
}  // end fctn


function  filterword ($s)
{
  $s = basename($s);
  if (preg_match('/^(\w+)$/', $s, $r)!=1)  return "";
  return $r[0];
}  // end fctn


function  filterid ($s)
{
  $s = basename($s);
  if (preg_match('/[\w-]*/', $s, $r)!=1)  return "";
  return $r[0];
}  // end fctn


function  filterdate ($s)
{
  $s = basename($s);
  if (preg_match('/[\w-:\.]*/', $s, $r)!=1)  return "";
  return $r[0];
}  // end fctn



function  struct2array ($struct)
{
  $res = array();
  foreach ( $struct as $field => $value )  $res[$field] = $value;
  return  $res;
}


function  structarray2array ($structarray)
{
  $res = array();
  foreach ( $structarray as $record )
    $res[] = struct2array($record);
  return  $res;
}


function  struct2stringarray ($struct)
{
  $res = array();
  foreach ( $struct as $field => $value )
  {
    $print = false;
    if ( gettype($value) == "string" )  $print = true;
    else if ( gettype($value) == "integer" )  $print = true;
    else if ( gettype($value) == "double" )  $print = true;
    else if ( gettype($value) == "boolean" )  $print = true;
    if ( $print )  $res[$field] = $value;
    else  $res[$field] = "";
  }
  return  $res;
}


function  structarray2stringarray ($structarray)
{
  $res = array();
  foreach ( $structarray as $record )
    $res[] = struct2stringarray($record);
  return  $res;
}


function  curl_post ($url,$port,$a_query,$a_body)
{
  $attempt_n = 3;
  $query = $a_query;
  $body = $a_body;
  $url = $url."?".$query;
  $curl = curl_init();
  curl_setopt($curl, CURLOPT_URL, $url);
  curl_setopt($curl, CURLOPT_PORT, $port);
  curl_setopt($curl, CURLOPT_VERBOSE, 0);
  curl_setopt($curl, CURLOPT_HEADER, 0);
  curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0);
  curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, 0);
  curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);
  curl_setopt($curl, CURLOPT_MAXREDIRS, 20);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
  // curl_setopt($curl, CURLOPT_HTTPHEADER,$header);
  if ( strlen($body) > 0 )
  {
    curl_setopt($curl, CURLOPT_POSTREDIR, CURLOPT_POSTREDIR);
    curl_setopt($curl, CURLOPT_POST, 1);
    curl_setopt($curl, CURLOPT_POSTFIELDS,$body);
  }
  for ( $i = 0 ; $i < $attempt_n ; $i++ )
  {
    $data = curl_exec($curl);
    if(!curl_errno($curl))  break;
  }
  curl_close($curl);
  return $data;
}  // end fctn


function  print_csv ($list, $sort="", $filter = "", $format="html",$width="400px")
{
  $sep = ",";
  $quote = "\"";
  $eol = "\015\012";

  if ( count($list) == 0 )  return;

  if ( $format == "html" )
    print("<table id=\"table01\" style=\"margin-top: 20px; margin-bottom: 10px; min-width: ".$width."; \" >\n");


  $order = "asc";
  if ( substr($sort,0,1) == "-" )  $order = "desc";
  if ( substr($sort,0,1) == "+" )  $sort = substr($sort,1);
  if ( substr($sort,0,1) == "-" )  $sort = substr($sort,1);
  $listsorted = array();
  for ( $recordid = 1 ; $recordid < count($list) ; $recordid++ )
  {
    $record = $list[$recordid];
    $v = "";
    if ( strlen($sort) > 0 )  $v = $record[$sort];
    foreach ( $record as $f )  $v .= "|".$f;
    $listsorted[] = $v;
  }  // end for
  if ( strlen($sort) > 0 )
  {
    if ( $order == "asc" )  sort($listsorted);
    else  rsort($listsorted);
  }

  $count = 0;

  $record = $list[0];
  $first = true;
  foreach ( $record as $n => $field )
  {
    $td = "th";
    if ( $format == "html" )  print("<".$td." >");
    if ( ( $format == "csv" ) && ! $first )  print($sep);
    if ( $format == "csv" ) print($quote);
    print(urldecode($field));
    if ( $format == "csv" ) print($quote);
    if ( $format == "html" )  print("</".$td.">");
    $first = false;
  }
  if ( $format == "csv" )  print($eol);
  

//print("<pre>\n");  
//print_r($list);
//print("\n----\n");
//print_r($listsorted);
//print("\n</pre>\n");  

  $head = false;
  for ( $i = 0 ; $i < count($listsorted) ; $i++ )
  {
    //$record = $list[$i];

    $value = $listsorted[$i];
    $record = NULL;
    $v = "(void)";
    for ( $recordid = 0 ; $recordid < count($list) ; $recordid++ )
    {
      $record = $list[$recordid];
      $v = "";
      if ( strlen($sort) > 0 )  $v = $record[$sort];
      foreach ( $record as $f )  $v .= "|".$f;
      if ( $v == $value )  break;
    }

    $tr = false;
    $first = true;
    foreach ( $record as $n => $field )
    {
      if ( strlen($filter) > 0 )
      {
        if ( $record["status"] != $statefilter )
          continue;
      }
      if ( ! $tr && ( $format == "html" ))  { print("<tr >\n");  $tr = true; }

      $style = "";
      $td = "td";
      if ( $head )  { $td = "th";  $style = ""; }
      if ( $format == "html" )  print("<".$td." style=\"".$style."\" >");
      if ( ( $format == "csv" ) && ! $first )  print($sep);
      if ( $format == "csv" ) print($quote);
      print(urldecode($field));
      if ( $format == "csv" ) print($quote);
      if ( $format == "html" )  print("</".$td.">");
      $first = false;
    }
    if ( $format == "csv" )  print($eol);
    if ( $tr )  { print("</tr >\n");  $head = false; }
    $head = false;
    $count++;
  }  // end foreach
  
  if ( $format == "html" )
  {
    print("</table>\n");
    print("<p style=\"margin-left: 10px; margin-top: 4px; margin-bottom: 30px; \" ><small>rows: ".$count."</small></p>\n");
  }  // end if

}  // end fctn


function  parse_csv ($s,$sep)
{
  $r = array();
  $r = explode($sep,$s);
  return $r;
}  // end fctn


if ( ! function_exists("format_uuid") )
{
function  format_uuid ($uuid)
{
  $uuid = str_replace('-','',$uuid);
  $uuid = substr($uuid,0,32);
  $uuid = strtoupper($uuid);
  $uuidn = '';
  $uuidn .= substr($uuid,0,8);
  $uuidn .= '-';
  $uuidn .= substr($uuid,8,4);
  $uuidn .= '-';
  $uuidn .= substr($uuid,12,4);
  $uuidn .= '-';
  $uuidn .= substr($uuid,16,4);
  $uuidn .= '-';
  $uuidn .= substr($uuid,20,12);
  return $uuidn;
}  // end fctn
}

if ( ! function_exists("format_euuid") )
{
function  format_euuid ($uuid)
{
  $uuid = str_replace('-','',$uuid);
  $uuid = substr($uuid,0,40);
  $uuid = strtoupper($uuid);
  $uuidn = '';
  $uuidn .= substr($uuid,0,8);
  $uuidn .= '-';
  $uuidn .= substr($uuid,8,4);
  $uuidn .= '-';
  $uuidn .= substr($uuid,12,4);
  $uuidn .= '-';
  $uuidn .= substr($uuid,16,4);
  $uuidn .= '-';
  $uuidn .= substr($uuid,20,12);
  $uuidn .= '-';
  $uuidn .= substr($uuid,32,8);
  return $uuidn;
}  // end fctn
}

function  uuid ($ref="")
{
  if ( strlen($ref) == 0 )  $ref = date('U',time()).rand().microtime();
  return format_uuid(sha1($ref));
}  // end fctn


function  euuid ($ref)
{
  if ( strlen($ref) == 0 )  $ref = date('U',time()).rand().microtime();
  return format_euuid(sha1($ref));
}  // end fctn


if ( ! function_exists("encrypt") )
{
function  encrypt ($key,$iv,$str)
{
  $key = str_replace('-','',$key);; 
  $key = pack('H'.strlen($key), $key); 
  $iv = str_replace('-','',$iv);
  $iv = pack('H'.strlen($iv), $iv); 
  $td = mcrypt_module_open('rijndael-128', '', 'ctr', ''); 
  mcrypt_generic_init($td, $key, $iv);
  $e_msg = @mcrypt_generic($td, $str); 
  $hex = bin2hex($e_msg);
  mcrypt_generic_deinit($td);
  mcrypt_module_close($td);
  return $hex;
}  // end fctn
}

if ( ! function_exists("decrypt") )
{
function  decrypt ($key,$iv,$str)
{
  $key = str_replace('-','',$key);; 
  $key = pack('H'.strlen($key), $key); 
  $iv = str_replace('-','',$iv);
  $iv = pack('H'.strlen($iv), $iv); 
  $td = mcrypt_module_open('rijndael-128', '', 'ctr', ''); 
  mcrypt_generic_init($td, $key, $iv);
  //$data = hex2bin($str);  // requires php 5.4 or later
  $data = pack('H'.strlen($str), $str);
  $e_msg = mdecrypt_generic($td, $data);
  mcrypt_generic_deinit($td);
  mcrypt_module_close($td);
  return $e_msg;
}  // end fctn
}


if ( ! function_exists("crc16") )
{
function  crc16 ($data)
{
  $crc = 0;
  for ( $i = 0 ; $i < strlen($data) ; $i++ )
  {
    $c = substr($data,$i,1);
    $crc  = ($crc >> 8) | ($crc << 8);
    $crc ^= ord($c);
    $crc ^= ($crc & 0xff) >> 4;
    $crc ^= ($crc << 8) << 4;
    $crc ^= (($crc & 0xff) << 4) << 1;
  }  // end for
  return strtoupper(substr(sprintf("%04x",$crc),0,4));
}  // end fctn
}


// generate LPID
// TESTFILE1XXXXXXXXXXXXXXXXXXXXX-0FD3
// 012345678901234567890123456789
if ( ! function_exists("lpid") )
{
function  lpid ($s)
{
  $r = "";
  for ( $i = 0 ; $i < strlen($s) ; $i++ )
  {
    $c = substr($s,$i,1);
    if ( ( ord($c) >= ord('A') ) && ( ord($c) <= ord('Z') ) )  $r .= $c;
    else if ( ( ord($c) >= ord('a') ) && ( ord($c) <= ord('z') ) )  $r .= $c;
    else if ( ( ord($c) >= ord('0') ) && ( ord($c) <= ord('9') ) )  $r .= $c;
  }
  $r = substr($r,0,30);
  $r = str_pad($r,30,"X");
  $r = strtoupper($r);
  $r .= "-".crc16($s); 
  return $r;
}  // end fctn
}


/*
if ( ! function_exists("crc32") )
{
function  crc32 ($data)
{
  $crc = 0;
  for ( $i = 0 ; $i < strlen($data) ; $i++ )
  {
    $c = substr($data,$i,1);
    $crc  = ($crc >> 8) | ($crc << 8);
    $crc ^= ord($c);
    $crc ^= ($crc & 0xff) >> 4;
    $crc ^= ($crc << 8) << 4;
    $crc ^= (($crc & 0xff) << 4) << 1;
  }  // end for
  return strtoupper(substr(sprintf("%04x",$crc),0,4));
}  // end fctn
}
 */

// generate eLPID
// TESTFILE1XXXXXXXXXXXXXXXXXXXXX-0FD3
// 012345678901234567890123456789
if ( ! function_exists("elpid") )
{
function  elpid ($s)
{
  $r = "";
  for ( $i = 0 ; $i < strlen($s) ; $i++ )
  {
    $c = substr($s,$i,1);
    if ( ( ord($c) >= ord('A') ) && ( ord($c) <= ord('Z') ) )  $r .= $c;
    else if ( ( ord($c) >= ord('a') ) && ( ord($c) <= ord('z') ) )  $r .= $c;
    else if ( ( ord($c) >= ord('0') ) && ( ord($c) <= ord('9') ) )  $r .= $c;
  }
  $r = substr($r,0,60);
  $r = str_pad($r,60,"X");
  $r = strtoupper($r);
  $r .= "-".crc16($s); 
  return $r;
}  // end fctn
}


if ( ! function_exists("file_base") )
{
function  file_base ($s)
{
  $v = pathinfo($s);
  $r = arraygetstr($v,"filename");
  return $r;
}  // end fctn
}


if ( ! function_exists("file_ext") )
{
function  file_ext ($s)
{
  $v = pathinfo($s);
  $r = arraygetstr($v,"extension");
  return $r;
}  // end fctn
}


if ( ! function_exists("curl_get_file_size") )
{
function curl_get_file_size( $url )
{
  // Assume failure.
  $result = -1;

  $curl = curl_init( $url );

  // Issue a HEAD request and follow any redirects.
  curl_setopt( $curl, CURLOPT_NOBODY, true );
  curl_setopt( $curl, CURLOPT_HEADER, true );
  curl_setopt( $curl, CURLOPT_RETURNTRANSFER, true );
  curl_setopt( $curl, CURLOPT_FOLLOWLOCATION, true );
  curl_setopt( $curl, CURLOPT_MAXREDIRS, 20);
  curl_setopt( $curl, CURLOPT_FRESH_CONNECT, 1);
  $headers = array( "Cache-Control: no-cache" ); 
  curl_setopt( $curl, CURLOPT_HTTPHEADER, $headers);
  //curl_setopt( $curl, CURLOPT_TIMEOUT_MS, 2000);
  //curl_setopt( $curl, CURLOPT_USERAGENT, get_user_agent_string() );

  $data = curl_exec( $curl );
  curl_close( $curl );

  if( $data )
  {
    $content_length = -2;
    $status = "unknown";

    if( preg_match( "/^HTTP\/1\.[01] (\d\d\d)/i", $data, $matches ) )
      $status = (int)$matches[1];

    if( preg_match( "/Content-Length: (\d+)/i", $data, $matches ) )
      $content_length = (int)$matches[1];

    // http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
    if( $status == 200 || ($status > 300 && $status <= 308) )
      $result = $content_length;
  }

  return $result;
}  // end fctn
}


if ( ! function_exists("curl_get_file_etag") )
{
function curl_get_file_etag( $url )
{
  // Assume failure.
  $result = -1;

  $curl = curl_init( $url );

  // Issue a HEAD request and follow any redirects.
  curl_setopt( $curl, CURLOPT_NOBODY, true );
  curl_setopt( $curl, CURLOPT_HEADER, true );
  curl_setopt( $curl, CURLOPT_RETURNTRANSFER, true );
  curl_setopt( $curl, CURLOPT_FOLLOWLOCATION, true );
  curl_setopt( $curl, CURLOPT_MAXREDIRS, 20);
  //curl_setopt( $curl, CURLOPT_TIMEOUT_MS, 2000);
  //curl_setopt( $curl, CURLOPT_USERAGENT, get_user_agent_string() );

  $data = curl_exec( $curl );
  curl_close( $curl );

  if( $data )
  {
    $content_length = -2;
    $status = "unknown";

    if( preg_match( "/^HTTP\/1\.[01] (\d\d\d)/i", $data, $matches ) )
      $status = (int)$matches[1];

    if( preg_match( "/ETag: \"(\w+)\"/i", $data, $matches ) )
      $content_length = $matches[1];

    // http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
    if( $status == 200 || ($status > 300 && $status <= 308) )
      $result = $content_length;
  }

  return $result;
}  // end fctn
}




/**
  @param match: associative array with key=>value fnmatch
 */

if ( ! function_exists("csv_filter") )
{
function csv_filter ($path,$csvsep,$linemax,$match,&$list,$onlyone=false)
{
  $list = array();
  $entry = array();
  $header = array();
  if ( ! file_exists($path) )
  {
    errmsg_set(__LINE__." csv_filter: file does not exist: ".$path);
    errno_set(__LINE__);
    return errno_get();
  }
  $fp = fopen($path,"r");
  $first = true;
  while ( $line = fgetcsv($fp,$linemax,$csvsep) )
  {
    if ( $first )  { $header = $line;  $first = false;  continue; }
    $record = array();
    for ( $i = 0 ; $i < count($line) ; $i++ )
      if ( isset($header[$i]) )
        $record[$header[$i]] = $line[$i];
    $ok = true;
    foreach ( $match as $mk => $mv )
      foreach ( $record as $rk => $rv )
        if ( fnmatch($mk,$rk,0) && ! fnmatch($mv,$rv,0) )  $ok = false;
    if ( $ok )  $list[] = $record;
    if ( $ok && $onlyone )  break;
  }  // end while
  fclose($fp);
  return 0;
}  // end fctn
}



if ( ! function_exists("lock") )
{
function lock ($flock,$timeout=120)
{
  while ( file_exists($flock) )
  {
    $lock = intval(file_get_contents($flock));
    if ( ( time() - $lock ) > $timeout )  unlink($flock);
    else  usleep(rand(250000,300000));
  }
  file_put_contents($flock,time());
  return 0;
}  // end fctn
}


if ( ! function_exists("unlock") )
{
function  unlock ($flock)
{
  unlink($flock);
  return 0;
}  // end fctn
}


if ( ! function_exists("nop") )
{
function  nop ()
{
}  // end fctn
}


if ( ! function_exists("lsdir") )
{
// function  lsdir ($path,$sort,$recursive,$offset,$limit,&$r)
function  lsdir ($path,$sort,$recursive,$limit,&$r)
{
  if ( ! isset($r) )  $r = array();
  if ( $r == null )  $r = array();
  while ( $path{strlen($path)-1} == "/" )  $path = substr($path,0,strlen($path)-1);
  if ( is_dir($path) )  $path .= "/*";
  $dir = dirname($path);
  $fmatch = basename($path);
  if ( $dh = opendir($dir) )
  {
    while (($file = readdir($dh)) !== false)
    {
      if ( $file == "." )  continue;
      if ( $file == ".." )  continue;
      if ( ( $limit > 0 ) && ( count($r) >= $limit ) )  break;
      $fp = $dir . "/" . $file;
      if ( fnmatch($fmatch,$file,0) )  $r[] = $fp;
      if ( is_dir($fp) && $recursive )  lsdir($fp,false,true,$limit,$r);
    }
    closedir($dh);
  }
  if ( $sort )  sort($r);
  return 0;
}  // end fctn
}


// ---------------------------------------------------------------------------


// EOF!

