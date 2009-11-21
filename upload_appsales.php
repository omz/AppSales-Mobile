<?php

   //
   // This script takes care of saving report files received from AppSales-Mobile
   //
   // Created by Edward Patel, Memention AB, http://memention.com/blog
   //
   // 1 - Place it in the users 'Site' directory
   // 2 - Change the BACKUP_HOSTNAME in the RootViewController.m file
   // 3 - When placing the app in a new device, copy all backup files to the 
   //     Prefetched directory in the Xcode project
   //     

   $filedir = '/tmp/AppSales-Backup/'; // Change to convenient place, and make so user www can write 

   if (isset( $_POST['filename'] ) &&
       isset( $_FILES ) &&
       isset( $_FILES['report'] )) {

     if (!file_exists( $filedir )) {
       mkdir( $filedir );
     }
   
     move_uploaded_file($_FILES['report']['tmp_name'], 
                        $filedir . $_POST['filename']);

   } else {
   
   ?> 

<html>
  <head>
  </head>
  <body>
    <h2>This is a receiver script for AppSales for backup of report files</h2>
    All it does is to receive files from your personal AppSales app and place them in <code><?=$filedir?></code>
  </body>
</html>

   <?php
   
   }

?>
