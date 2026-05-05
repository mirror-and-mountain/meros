<?php
$i = 0;
$i++;
$cfg['Servers'][$i]['host'] = 'db';
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['user'] = 'dbuser';
$cfg['Servers'][$i]['password'] = 'dbpassword';
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['blowfish_secret'] = 'a-random-string-here-for-dev-12345678901234';
$cfg['DefaultLang'] = 'en';
$cfg['ServerDefault'] = 1;
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
// Disable HTTPS redirect
$cfg['PmaAbsoluteUri'] = 'http://localhost:9000';