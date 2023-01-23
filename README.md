
- [What it is](#what-it-is)
- [What it isn't](#what-it-isnt)
- [Copyrights](#copyrights)
- [Why repo is so heavy](#why-repo-is-so-heavy)
- [I want to try it!](#i-want-to-try-it)
- [What's inside it](#whats-inside-it)
- [TODO:](#todo)
# What it is
This is a distributed Wordpress website with nginx in front, acting as loadbalancing proxy. 
Website uses mysql with master-slave replication, with autobackups from slave.
There is prometheus/grafana stack for monitoring, and ELK stack for centralised logging
# What it isn't
It isn't production-ready solution. You need to tweak it extensively, if you want to use it as production system. 
# Copyrights
All rights for provided rpms and binaries (ELK, prometheus, grafana, *_exporter) belong to original developers and companies.
# Why repo is so heavy
Because it contains rpms. Sometimes official repositories don't work for some reason.
# I want to try it!
To try this project you'll need:
1. Control node with ansible 2.11+
2. install ansible posix collection:
```
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.mysql
```
3. 3 virtual machines, based on CentOS (RedHat):
   | VM  | vCPU | RAM | Used for                    |
   | --- | ---- | --- | --------------------------- |
   | 1   | 1    | 2   | nginx, apache, mysql master |
   | 2   | 1    | 2   | apache, mysql slave         |
   | 3   | 1    | 4   | ELK, prometheus, grafana    |

4. Working ssh key authentication for authenticating as root
5. Clone this repository
6. Edit ansible/inventory.yaml, input your VM ip addresses.
7. Use provided rpms and binaries from https://github.com/taihon/otus-basic-final/releases/tag/rpm-0.1 (download and extract to "files/"), or provide your own
8. Check out ansible/vars/extra.json, change it according to your needs
9. Run playbook in your terminal with command
```
ansible-playbook -i inventory.yaml -e="@vars/extra.json"  playbook.yml
```

# What's inside it
Included groups:

- backends - these are apache (httpd) workers
- frontends - these are nginx loadbalancing proxies (you really need only one)
- dbservers - these are replicating master-slave mysql8 servers. Roles are based on host variables (replication_role=master|slave)
- monitoring - this is prometheus+grafana
- logging - this is ELK
- monitored - these are servers that share their metrics and send logs to ELK.

All configuration is splitted into following roles:

- backend_httpd:
  - installs httpd
  - creates config from template
  - opens port 81/tcp
  - enables selinux policy 'httpd_can_network_connect_db'
- backend_php: 
  - installs php8-related packages from Remi repository
- backend_website:
  - downloads wordpress 6.1.1 (version is frozen for now) on control node
  - copies it to backends
  - extracts to www folder
  - creates wp-config.php
  - pointing to master dbserver (dependency)
- dbserver:
  - installs mysql8-community
  - performs mysql secure actions (changes root password, denies root remote logon, removes anonymous logins, removes test db)
  - sets up master-slave replication, based on host vars (replication_role=master|slave)
  - creates wordpress database and user for wordpress
  - opens 3306/tcp in firewalld
- frontend_nginx:
  - installs nginx
  - creates config from template
  - installs nginx_prometheus_exporter
- logger_server:
  - installs openjdk
  - installs ELK either from official repository, or from static rpms if "use_rpms" is set to true
  - tunes elasticsearch jvm options to use max 2GB of RAM 
  - tunes elasticsearch service start timeout (this is slow because of insufficient memory)
  - enables kibana to answer remotely
  - creates logstash pipeline config and enables it to load
  - open ports 5601 (kibana) and 5400 (logstash beats input)
- logging_node:
  - installs filebeat from official repository or rpm if "use_rpms" is set to true
  - creates config (filebeat.yml) from template, pointing to logstash
- monitored_node:
  - copies node_exporter binary and creates systemd service for it
  - opens port 9100 in firewalld
- monitoring_server
  - copies prometheus binary and creates systemd service for it
  - copies grafana rpm and installs it
  - copies grafana.db from backup, to restore dashboards
  - opens ports 3000 (grafana) and 9090 (prometheus)
- ntp_client
  - installs ntp, ntpdate
  - requests time update from 1.ru.pool.ntp.org

# TODO:

- [ ] automate VM creation with some sort of VM provisioning solution like Terraform
- [ ] sync media files between backends
- [ ] eliminate CentOS requirements for nodes