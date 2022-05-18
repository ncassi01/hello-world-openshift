### Placeholder folder for generating sealed secrets

- This folder is for placing files with example plaintext credentials used to created sealed secrets. 
- In practice, these files should never be added to the repository only the sealed secrets generated from these files.

```generate_sealedsecrets.sh``` script will take files from this folder and convert these to sealed secrets and save them in the sealedsecrets folder.

For example:
> /secrets/files/mysecrets.properties
> /secrets/files/datasource-exampledb.xml 