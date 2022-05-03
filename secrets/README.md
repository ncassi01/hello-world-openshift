### Placeholder folder for generating sealed secrets
This folder is for placing files with plaintext credentials used to created sealed secrets. 

generate_sealedsecrets.sh script will take files from this folder and convert these to sealed secrets and save them in the sealedsecrets folder.

For example:
> /secrets/files/datasource-denodo.xml