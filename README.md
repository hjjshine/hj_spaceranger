This is a temporary repository for incorporating the latest version of Spaceranger (v4.0) into the Cumulus pipeline.

Includes:
- Docker images required for running Cumulus pipeline (with Spaceranger v4.0 installed)
- Workflow pipelines (work in progress)

Building and pushing docker images:
- Please download the spaceranger tar.gz file in this folder `dockers/spaceranger-4.0.1`, and then run the following commands to build and push the docker images.

```
docker buildx build \
--platform linux/amd64 \ #for terra workflows
--push \
-t gcr.io/vanallen-junhyeji/spaceranger:4.0.1 \
--no-cache .
```
  
```
docker buildx build \
--platform linux/amd64 \
--push \
-t gcr.io/vanallen-junhyeji/config:0.3 \
--no-cache .
```


