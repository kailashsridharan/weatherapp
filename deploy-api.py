import os
import sys
if sys.version_info[0] < 3:
    raise Exception("Must be using Python 3")
import subprocess
import traceback
import time
import boto3
import base64

def registry_login_cli(username, password, registry ):
    """
    Login to the AWS ECR 
    Input:
        username: Username to login in this case AWS
        password: The Authorization token for the registry
        registry: The registry to login and push images
    Returns:
        status: Bool : login status
    """
    print('INFO: Logging into the remote server')
    print('INFO: The REGISTRY URL before login is '+ registry)
    try:
        command = 'docker login '+ '-u '+ username + ' -p '+ password +' '+ registry
        call_value = subprocess.call(command, shell=True)

        if call_value == 0:
            return True
        else:
            return False
    except Exception as ex:
        print(ex)
        print('ERROR: logon failed')
        return False

def build_api_docker_image():
    '''
    Builds the Docker image of the app
    Input: None
    Returns: None
    '''
    print("\n\n****************************** Building Docker Image ******************************")
    print("Loading AWS Docker Image...")
    try:
        if os.path.exists("app/docker-compose.yml"):
            command_load = "docker compose -f app/docker-compose.yml build"

            output_load = subprocess.run(command_load, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
            if output_load.returncode == 0:
                print(output_load.stdout)
                print("INFO: Docker Image Build Successfull")
            else:
                print(output_load.stderr)
                print("ERROR: Couldn't load the AWS Orchestration Docker Image")
                sys.exit(1)
        else:
            print("ERROR: File aws_orchestration_deploy.tar.gz is not present in the current directory...")
            sys.exit(1)
    except Exception as e:
        print("ERROR: Couldn't load the docker image...")
        print(e)
        sys.exit(1)

def create_ecr_repo(region):
    """ Create ECR Repo if the Repos in the region Doesn't Exist
        Input : 
            Region: Region in which the ECR repo is supposed to be created
       Return: None
    """
    try:
        image_name_with_before_tag = ["infraapi", "infraweb"]
        for images in image_name_with_before_tag:        
            print("INFO: creating repository: " + images)
            ecr_client = boto3.client('ecr', region_name=region)
            response = ecr_client.create_repository(
            repositoryName = str(images),
            imageTagMutability='MUTABLE',
            imageScanningConfiguration={
                'scanOnPush': True
            }
        )
    except ecr_client.exceptions.RepositoryAlreadyExistsException as e:
        print('INFO: The repositry already exists, not creating')
        pass
    except Exception as e:
        print(e)
        print("ERROR: Error create repo failed")

def get_registry_url(region):
    """ Get the target registry and log in to the target registry
        Input : 
            Region: Region in which the ECR repo is supposed to be created
       Return: Bool/Registry string
    """
    try:
        sts = boto3.client('sts', region_name=region)
        target_account_id = sts.get_caller_identity()["Account"]
        ecr_client = boto3.client('ecr', region_name=region)
        ecr_credentials = (
            ecr_client
            .get_authorization_token()
            ['authorizationData'][0])
        ecr_username = 'AWS'
        ecr_password = (
            base64.b64decode(ecr_credentials['authorizationToken'])
            .replace(b'AWS:', b'')
            .decode('utf-8'))
        registry = target_account_id +'.dkr.ecr.' + region + '.amazonaws.com'
        registry_login_cli(ecr_username, ecr_password, registry)
        return registry
    except Exception as ex:
        print(ex)
        print('ERROR: logon failed')
        return False
    
def tag_image(image_name, registry_url):
    """ 
        Tag the docker images to push in to aws ECR
        Input : 
            image_name: Name of the image that need to be pushed
            registry_url: ECR Registry
       Return: Bool
    """
    #out = os.popen('docker image ls > tags_of_images.txt').read()
    try:
        print("\n\n****************************** Tagging Docker Image to push to the repo******************************")
        image_name_with_version_tagged = []
        print('images to be tagged are', image_name)
        for images in image_name:
                    image_name_with_before_tag = images + ":" + "latest"
                    image_name_with_after_tag = (registry_url + "/" + images + ":" + "latest").replace(" ", "")

                    command = 'docker tag ' + ' ' + image_name_with_before_tag + ' ' + image_name_with_after_tag
                    print(command)
                    try:
                        proc = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
                    except IOError as e:
                        print('ERROR: I/O error({0}): {1}'.format(e.errno, e.strerror))
                        return False
                    except Exception as e: #"Other unknows errors"
                        print('ERROR: Unexpected error:' + str(e))
                        return False
                    print('INFO: Result is for docker tag execution is '+ str(proc))

                    if proc.stderr:
                        print(proc.stderr)
                        print('ERROR: tag failed')
                        return False, None

                    else:
                        image_name_with_version_tagged.append(image_name_with_after_tag)
                        pass
        print('INFO: tag success')
        return image_name_with_version_tagged
    except Exception as ex:
        print(ex)
        print('ERROR: logon failed')
        return False
    
def push_image_cli(image_name_with_version):
    """
    Tag the docker images to push in to aws ECR
    Input : 
        image_name_with_version: Name of the image that need to be pushed
        Return: Bool
    """
    print("\n\n****************************** Pushing the Images in to the Repo******************************")
    try:
        for images in image_name_with_version:
            command = 'docker push '+ images
            print(command)
            proc = subprocess.call(command, shell=True)
            if proc == 0:
                print(f"INFO: Image {images} Success")                
            else:
                print(f"INFO: Image {images} Failed")
                return False
        return True
    except Exception as e:
        print('ERROR: Unknown Exception:' + str(e))
        return False


def infrastructure_setup(region):
    """
    Create the AWS resoruces through terraform
    Input : 
    region: Region of Deployment
    Return: Bool
    """
    try:
        print("\n\n****************************** Building the Infrastructure on AWS******************************")

        # run terraform code to provision infra required and to install helm charts on eks cluster
        print('INFO: Starting terraform scripts to provision required infrastructure')
        root_dir = os.path.dirname(__file__)
        process = subprocess.run('terraform init', stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
        time.sleep(10)
        process = subprocess.run('terraform plan', stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
        time.sleep(10)
        process = subprocess.run('terraform apply --auto-approve', stderr=subprocess.STDOUT, shell=True, universal_newlines=True)       
        # Reading terraform logs
        time.sleep(10)
        process = subprocess.run('terraform output -json   > outputs.json',  stderr=subprocess.STDOUT, shell=True, universal_newlines=True, timeout=300)
        print('INFO: completed running terraform scripts')
        kube_config_command = f'aws eks update-kubeconfig --region {region} --name weatherapp'
        process = subprocess.run(kube_config_command,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True)

        return True
    except IOError as e:
        print('I/O error({0}): {1}'.format(e.errno, e.strerror))
        print(traceback.format_exc())
    except Exception as e:
        print('ERROR: Unknown Exception:' + str(e))

def install_kube_manifests(images):
    """
    Create the AWS resoruces through terraform
    Input : 
    images: List of Images and their tags
    Return: Bool
    """
    try:
        print("\n\n****************************** Installing the Kubernetes Manifests******************************")

        root_dir = os.getcwd()
        create_ns = f"kubectl create namespace app-ns"
        process = subprocess.run(create_ns,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True, timeout=300)
        kubemanifest = f"kubectl apply -f kube-manifests/ -n app-ns"
        process = subprocess.run(kubemanifest,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True, timeout=300)
        infraapi_cmd = f"kubectl set image deployment/infraapi infraapi={images[0]} -n app-ns"
        process = subprocess.run(infraapi_cmd,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True, timeout=300)
        infraweb_cmd = f"kubectl set image deployment/infraweb infraweb={images[1]} -n app-ns"
        process = subprocess.run(infraweb_cmd,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True, timeout=300)
        print("INFO: Waiting a minute for the resources to be available")
        time.sleep(60)
        get_lb_command = 'kubectl get services infraweb-service -n app-ns'
        process = subprocess.run(get_lb_command, stderr=subprocess.STDOUT, shell=True, universal_newlines=True, timeout=300)
    except subprocess.TimeoutExpired:
        pass
    except Exception as ex:
        print(traceback.format_exc())
        raise ex
def destroy_cluster(region):
    """
    Delete the Cluster and clean up
    Input : 
    region: Region where the cluster is deployed
    Return: Bool

    """
    print("\n\n****************************** Destroying and Cleaning up******************************")

    kube_config_command = f'aws eks update-kubeconfig --region {region} --name weatherapp'
    process = subprocess.run(kube_config_command,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
    get_all_command = f'kubectl get all --namespace=app-ns -o yaml > app-ns.yaml'
    delete_all_command = f'kubectl delete -f app-ns.yaml'
    print('INFO: Deleting the contents of the Namespace to unprovision EKS components')
    process = subprocess.run(get_all_command,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
    process = subprocess.run(delete_all_command,  stderr=subprocess.STDOUT, shell=True, universal_newlines=True, timeout=300)
    print('INFO: Errors Can be ignored as replica sets will be deleted when deployment is')
    print("INFO: Waiting for 3 mins for Loadbalancers to clear out")
    time.sleep(180)
    process = subprocess.run(f'terraform init',stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
    time.sleep(10)
    process = subprocess.run('terraform plan', stderr=subprocess.STDOUT, shell=True, universal_newlines=True)
    time.sleep(10)
    process = subprocess.run('terraform destroy --auto-approve' , stderr=subprocess.STDOUT,shell=True, universal_newlines=True)

if __name__ == '__main__':
    try:
        region = input("Enter Region, Please make sure the region is the same as the terraform variables: ")
        args = sys.argv[1:]
        if args and 'destroy' in args:
            destroy_cluster(region)
            sys.exit(1)
        build_api_docker_image()
        create_ecr_repo(region)
        registry_url = get_registry_url(region)
        if registry_url:
            image_name_with_version_tagged = tag_image(["infraapi", "infraweb"], registry_url)
            print(image_name_with_version_tagged)
            push_image_cli(image_name_with_version_tagged)
            print("INFO: Pushing Images to the repository Succeeded")
        else:
            print("ERROR: Unable to get the registry URL, Pushing the Images Failed")
            raise Exception("ERROR: Unable to get the registry URL, Pushing the Images Failed")
        status = infrastructure_setup(region)
        status = install_kube_manifests(image_name_with_version_tagged)
        print("\n\n****************************** Deployment complete******************************")

    except Exception as e:
        print(e)
        print('ERROR: Pusing the Images to Repo has failed')