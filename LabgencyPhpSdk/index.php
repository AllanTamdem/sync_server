<?php
require_once("hss-client.inc.php");

$aid = 'A2C1BD14-A707-11E4-9476-17B7D42F3AC0';
$key = 'A3F3225E-A707-11E4-A636-D7D1B5924A10';
$ivkw = 'A52488E8-A707-11E4-839E-93FF64B57502';
$sigkw = 'A655EFE0-A707-11E4-ABB3-172551C2DEE8';
$service_id='orange.fcd';

// echo "yo";

$url = "https://api.labgency.ws/play/asr";
$port = 443;

$catalog = lgy_catalog($aid,$key,$ivkw,$sigkw,$url,$port,$service_id,$version=9999);

header('Content-Type: application/json');
echo json_encode($catalog);
?>