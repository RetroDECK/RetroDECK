import os
import shutil
import re

def resetfun(rdhome):
    if not os.path.exists(rdhome+"/.sync/"):
        os.makedirs(rdhome+"/.sync/")

    os.system("/app/bin/zypak-wrapper /app/srm/steam-rom-manager list")
    srm_path=os.path.expanduser("~/.var/app/net.retrodeck.retrodeck/config/steam-rom-manager/userData/userConfigurations.json")
    if not os.path.isfile(srm_path):
        print("Steam Rom Manager configuration not initialized! Initializing now.")
        shutil.copyfile("/app/libexec/steam-sync/userConfigurations.json", srm_path)

    with open(srm_path,"r") as f:
        data=f.read()
    data=re.sub("\"steamDirectory.*","\"steamDirectory\" : \""+os.path.expanduser("~/.steam/steam")+"\",",data)
    data=re.sub("\"romDirectory.*","\"romDirectory\" : \""+rdhome+"/.sync/\",",data)
    with open(srm_path,"w") as f:
        f.write(data)

if __name__=="__main__":
    rdhome=""

    print("Open RetroDECK config file: {}".format(os.path.expanduser("~/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.cfg")))

    fl=open(os.path.expanduser("~/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.cfg"),"r")
    lines=fl.readlines()
    for line in lines:
        if "rdhome" in line:
            rdhome=line[7:-1]
    fl.close()

    resetfun(rdhome)
