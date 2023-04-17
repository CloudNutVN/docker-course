![Overview](./images/installation-docker.png)  

## Prequisites  
| Required     | Version                                |  
|--------------|----------------------------------------|  
| Server | 2+ CPU, 2GB Memory, 20GB Free Disk | 
| OS           | Ubuntu 20.04                           |
  
  
## 1. Clone Github Repo
### 1.1. Fork repo

| Repo            |  URL| Note               |
|-----------------|---|--------------------|  
| `docker-course` | [HTTP](https://gitlab.com/hoabka/argo-cd.git) hoặc [SSH](git@gitlab.com:hoabka/argo-cd.git)  | Course Source code 

### 1.2. Install Docker
```bash
cd docker-lab/installation
chmod +x docker-install.sh
./docker-install.sh
```

### 1.3. Verify
```bash
docker ps
```
> **Note:** In case you got error as the following.
>> **Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get https://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json: dial unix /var/run/docker.sock: connect: permission denied**

**Solution:**
```bash
user=`whoami`
sudo usermod -aG docker $user
exit
# Access again with this user and it will works fine
```
