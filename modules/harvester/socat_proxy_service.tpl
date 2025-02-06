[Unit]
Description=Socat Service

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:443,fork TCP:192.168.122.120:443
Restart=always
User=root

[Install]
WantedBy=multi-user.target