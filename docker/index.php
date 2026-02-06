<?php
$host     = "maria";        // Matches the service name in docker-compose
$user     = "root";         
$password = "password";     
$database = "my_database"; 

// Connect to MariaDB
$conn = new mysqli($host, $user, $password, $database);

// Check connection
if ($conn->connect_error) {
    echo "<h2 style='color:red'>Connection Failed!</h2>";
    echo "<p>" . $conn->connect_error . "</p>";
} else {
    echo "<h2 style='color:green'>Success!</h2>";
    echo "<p>Connected to <b>" . $host . "</b> successfully.</p>";
    echo "<p><b>Database:</b> " . $database . "</p>";
    echo "<p><b>Server Version:</b> " . $conn->server_info . "</p>";
    echo "Hugo Mata";
}

$conn->close();
?>
