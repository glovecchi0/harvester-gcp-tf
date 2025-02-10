[Unit]
Description=Socat Service

[Service]
ExecStart=/bin/bash -c "/usr/bin/socat TCP-LISTEN:443,fork TCP:192.168.122.120:443 & /usr/bin/socat TCP-LISTEN:6443,fork TCP:192.168.122.120:6443 & wait"
Restart=always
User=root

[Install]
WantedBy=multi-user.target