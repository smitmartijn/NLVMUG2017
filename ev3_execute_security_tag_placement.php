<?php

require 'vendor/autoload.php';

$security_tag_allow_ping_moid = "securitytag-15";
$vm1_moid = "vm-168";
$vm2_moid = "vm-169";

function NSX_API_Delete($url)
{
  $curl = curl_init();
  // set authentication
  curl_setopt($curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
  curl_setopt($curl, CURLOPT_USERPWD, "admin:VMware1!");
  // set url and other options
  curl_setopt($curl, CURLOPT_URL, $url);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
  curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, false);
  curl_setopt($curl, CURLOPT_HTTPHEADER, array('Content-Type: application/xml'));
  curl_setopt($curl, CURLOPT_HEADER, true);

  curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "DELETE");

  // execute operation
  return curl_exec($curl);
}

function NSX_API_Put($url)
{
  $curl = curl_init();
  // set authentication
  curl_setopt($curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
  curl_setopt($curl, CURLOPT_USERPWD, "admin:VMware1!");
  // set url and other options
  curl_setopt($curl, CURLOPT_URL, $url);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
  curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, false);
  curl_setopt($curl, CURLOPT_HTTPHEADER, array('Content-Type: application/xml'));
  curl_setopt($curl, CURLOPT_HEADER, true);
  curl_setopt($curl, CURLOPT_PUT, 1);

  // execute operation
  return curl_exec($curl);
}

$app = new Slim\App();

$app->get('/VM1_green', function($request, $response, $args) {
  // delete the "Allow_PING" security tag from VM1
  $result = NSX_API_Delete("https://nsx.lab.corp:443/api/2.0/services/securitytags/tag/".$security_tag_allow_ping."/vm/".$vm1_moid);
  return $response->write($result);
});

$app->get('/VM2_green', function($request, $response, $args) {
  // delete the "Allow_PING" security tag from VM2
  $result = NSX_API_Delete("https://nsx.lab.corp:443/api/2.0/services/securitytags/tag/".$security_tag_allow_ping."/vm/".$vm2_moid);
  return $response->write($result);
});

$app->get('/VM1_red', function($request, $response, $args) {
  // put the "Allow_PING" security tag from VM1
  $result = NSX_API_Put("https://nsx.lab.corp:443/api/2.0/services/securitytags/tag/".$security_tag_allow_ping."/vm/".$vm1_moid);
  return $response->write($result);
});

$app->get('/VM2_red', function($request, $response, $args) {
  // put the "Allow_PING" security tag from VM2
  $result = NSX_API_Put("https://nsx.lab.corp:443/api/2.0/services/securitytags/tag/".$security_tag_allow_ping."/vm/".$vm2_moid);
  return $response->write($result);
});











$app->run();
