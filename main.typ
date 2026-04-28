#import "@preview/colorful-boxes:1.4.3": colorbox

#set text(
  font: "New Computer Modern",
  size: 14pt
)

#set par(
  justify: true,
  leading: 0.52em,
)

#set heading(numbering: "1.")
#set page(numbering: "1")

#align(center)[
  #title[
    LEARNING KUBERNETES
  ]

  #set text(16pt)
  Stefano Zenaro
]


= Introduction

Kubernetes, also known as K8s, is an open source system for automating deployment, scaling, and management of containerized applications.

Kubernetes is a container orchestrator and has the following features:

- scalability: increase/decrease the resources depending on CPU usage, number of requests, ...
- self-healing: it restarts containers if they stop running.
- service discovery and load balancing: a DNS name is shared by a set of pods, which can be used to find and distribute traffic across the different pods.
- automated rollouts and rollbacks of changes that propagate gradually.
- storage orchestration: different types of storage are mounted and shared in the cluster.
- secrets and configuration management.
- automatic bin packing: chooses where to run containers based on requirements and constraints.

== Installation

To install Kubernetes, you first need the `kubectl` CLI tool, which is used to interact with the Kubernetes cluster.

Then, to run a local instance of Kubernetes to learn how it works, install minikube.

#colorbox([`kubectl` works on all types of Kubernetes clusters.], title: "Note")

In production, you can deploy Kubernetes in different ways:

- on premise
- using a cloud provider. The provider will give you a yaml file which contains information needed to access the cluster, which must be copied/appended to `~/.kube/config`.

#colorbox([`kubectl config get-clusters` returns a list of configurations for the clusters. `kubectl cluster-info` returns information about the cluster.], title: "Note")

There's also k3s, which is a lighter version of Kubernetes.

== Getting Started

Start the cluster with:

```sh
minikube start
```

#colorbox([Minikube starts a master node and a worker node on the same machine.], title: "Note")

See the current cluster status with:

```sh
minikube status
```

Open the Kubernetes web dashboard with:

```sh
minikube dashboard
```


== Cluster Components

A cluster has a control plane and one or more worker nodes.

=== Control Plane

The control plane is used to manage the state of the cluster.

It has the following components:

- `kube-apiserver`: exposes the Kubernetes HTTP API.

  It is used by the dashboard and the `kubectl` tool to manage new configurations (in YAML or JSON format).

- `etcd`: distributed (key, value) database with the Kubernetes configuration.
- `kube-scheduler`: schedules new pods to worker nodes depending on the resources that are available.
- `kube-controller-manager`: runs controllers, which are used to move the system to the desired state.
- `cloud-controller-manager`: used to integrate with a cloud provider. 

=== Worker Nodes

Nodes maintain running pods (with the applications running inside of them).

They have the following components:

- `kubelet`: ensures that the pods are running in a healthy/desired state.
- `kube-proxy`: it handles network rules to implement services (exposed applications)
- Container runtime: used to run the containers


== Concepts

=== Resources

Resources are the different components that are managed in Kubernetes,
and are tipically defined declaratively using configuration files.

They can also be created using `kubectl` but it's not best practice.

=== Namespaces

A namespace allows to organize resources.

To create a namespace, use:
```sh
kubectl create namespace <name>
```

To set the current namespace, use:
```sh
kubectl config set-context --current --namespace <name>
```

=== Pod

A pod is a group of containers, logically grouped together for management purposes.
Tipically, one pod contains one container with one application.

Each pod gets its own internal IP address, which changes every time the pod restarts.

By default, containers in a pod can't be accessed from outside the cluster's virtual network. To expose the pod, it must become a "Service".

Pods are ephemeral, like docker containers: they don't store permanent state/data themselves.

#colorbox([Persistent data can be stored in volumes.], title: "Note")

=== Deployment

A deployment is used to create and update instances of an application.
It can be seen as a blueprint for creating the application pods.

A deployment checks the health of the pods and starts them if they are not running.

Use the following command to create a pod with one container starting from an image:

```sh
kubectl create deployment <name> --image=<image> [-- <other>]
```

This command shows a list of deployments:

```sh
kubectl get deployments
```

This shows a list of pods:

```sh
kubectl get pods
```

List of cluster events:

```sh
kubectl get events
```

kubectl configuration:

```sh
kubectl config view
```

Shows logs of a pod:

```sh
kubectl logs <pod_name>
```

To delete a deployment, run:

```sh
kubectl delete deployment <name>
```

==== Configuration File

A deployment configuration file has:

- An `apiVersion` with the configuration version.
- `kind` set as `Deployment`.
- `metadata`, such as the `name` of the deployment.
- specification `spec`, which specifies which containers to run, how many replicas, ...
  It specifies the desired state.

  The `spec` contains a `template`, which is the blueprint of the pods.
  The `template` also has its own `metadata` and `spec`.

  The pod's `spec` contains the `containers` specification, with its image and port number. If applicable, it can also contain `volumes` which can be mounted to a container using `volumeMounts`.

The file also contains another component which is not managed by the user, which is the current state.

#colorbox([The state is contained inside etcd.], title: "Note")

```yaml
apiVersion: v1
kind: Deployment
metadata:
  name: myDeployment
  # namespace: myNamespace
spec:
  replicas: <N>
  selector:
    matchLabels:
      myLabel: myLabelValue
  template:
    metadata:
      labels:
        myLabel: myLabelValue
    spec:
      containers:
      - name: myContainer
        image: myImage:<version>
        ports:
        - containerPort: <port>
        volumeMounts:
        - mountPath: <path>
          name: myVolume
        env:
        - name: envVarName1
          value: envVarValue1
        - name: envVarName2
          valueFrom:
            secretKeyRef:
              name: mySecret
              key: mySecretKey
        - name: envVarName3
          valueFrom:
            configMapKeyRef:
              name: myConfigMap
              key: myConfigMapKey
      volumes:
      - name: myVolume
        persistentVolumeClaim:
          claimName: myVolumeClaim
```

The `selector` indicates that all the replicas that match the labels are part of the same deployment.

`valueFrom/secretKeyRef` is used to retrieve data from a `Secret`. Its `name` is the name of the `Secret`, while `key` is the name of the key which contains the secret itself.

A container can also specify the `resources` that are required or their limits:

```yaml
containers:
- name: myContainer
  ...
  resources:
    limits:
      memory: ...
      cpu: ...
    requests:
      memory: ...
      cpu: ...
```

=== Service

It is a pod which is exposed outside of the Kubernetes virtual network.
It also works as a load balancer.

To expose a pod, use:

```sh
kubectl expose deployment <deploy_name> --type=LoadBalancer --port=<port>
```

#colorbox([`port` is the port used inside the container.], title: "Note")

Use the following to see a list of services:
```sh
kubectl get services
```

Normally, the external IP can be used to access the service. With minikube, you need to run: 

```sh
minikube service <deploy_name>
```

To delete a service, run:

```sh
kubectl delete service hello-node
```

==== Configuration File

A service configuration file has:

- An apiVersion with the configuration version.
- kind set as `Service`.
- metadata, such as the `name` of the deployment.
- specification: it specifies the desired state.

The file also contains another component which is not managed by the user, which is the current state.

#colorbox([The state is contained inside etcd.], title: "Note")

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myService
  # namespace: myNamespace
spec:
  type: NodePort
  selector:
    # deployment selector
    myLabel: myLabelValue
  ports:
    - protocol: TCP
      port: <port1>
      targetPort: <port2>
      # specific to NodePort
      nodePort: <port3>
```

The `selector` indicates the labels of the pods which are exposed by the service.

The `targetPort` is the port of the deployment, which should be the same as the `containerPort` in the deployment.

There are different `type`s of services:

- `ClusterIP`: the service can be accessed by any pod within the cluster.

  To expose a `ClusterIP` service outside the cluster, you need to create an `Ingress` or a `Gateway`.

- `NodePort`: the service is accessible using the node's IP.
- `LoadBalancer`: the service is load-balanced across all nodes in the cluster.

  It can be accessed from outside the cluster.

  #colorbox([You need to set up the load balancer.], title: "Note")

=== Ingress

Forwards requests from outside the Kubernetes cluster to a service.
It is useful for setting up HTTPS and accessing the service using a URL instead of an IP.

A reverse proxy can be used for load balancing, which is the "Ingress Controller".
An Ingress Controller forwards traffic to the Ingress resourses.

#colorbox([Some examples of ingress controllers are nginx and traefik.], title: "Note")

=== ConfigMap

A `ConfigMap` allows to store external configurations for an application. Data is stored in plain text in (key, value) pairs.
It avoids having to build a new container if, for example, a value in an environment value must be changed.

It can contain URLs which are connected to the pod.

A `ConfigMap` can be accessed as environment variables or as a properties file.

==== Configuration File

A ConfigMap configuration file has:

- An `apiVersion` with the configuration version.
- `kind` set as `ConfigMap`.
- `metadata`, such as the `name` of the ConfigMap.
- `data`: it contains (key, value) pairs of data.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myConfigMap
data:
  key1: value1
  key2: value2
  filename.ext: |
    <fileContent>
```

Inside a `Deployment`, you can use `volumes` and `volumeMounts` to access the ConfigMap as a configuration file:

```yaml
containers:
- name: ...
  ...
  volumeMounts:
  - name: myConfigMapVolume
    # where the files will be located
    mountPath: <path>

volumes:
- name: myConfigMapVolume
  configMap:
    name: myConfigMap
```

Or as an environment variable:

```yaml
env:
- name: envVarName
  valueFrom:
    configMapKeyRef:
      name: myConfigMap
      key: myConfigMapKey
```

=== Secret

It is a special ConfigMap, used for storing secrets.
By default, it stores data using base64, but it is meant to be used with external services to encrypt the data.

They can be connected to a pod, which can use the data.

Secrets can be accessed as environment variables or as a properties file, just like ConfigMaps.

They are useful to store:

- credentials
- tokens
- certificates

==== Configuration File

A Secret configuration file has:

- An apiVersion with the configuration version.
- kind set as `Secret`.
- type set as `Opaque`.
- metadata, such as the `name` of the Secret.
- data: it contains (key, value) pairs of data, where the value is base64 encoded.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mySecret
type: Opaque
data:
  key1: value1
  key2: value2
```

You can use `stringData` instead of `data` to have the value in plain text in the yaml file but encoded in Kubernetes.

Inside a `Deployment`, you can use `volumes` and `volumeMounts` to access the Secret as a configuration file:

```yaml
containers:
- name: ...
  ...
  volumeMounts:
  - name: mySecretVolume
    # where the files will be located
    mountPath: <path>

volumes:
- name: mySecretVolume
  secret:
    secretName: mySecret
```

Or as an environment variable:

```yaml
env:
- name: envVarName
  valueFrom:
    secretKeyRef:
      name: mySecret
      key: mySecretKey
```

=== Volume

Volumes are used for persistent data storage.
It attaches storage to the pod, which can be either local or remote.

In a `Deployment`, you need to specify pod `volumes` and container's `volumeMounts`.

```yaml
containers:
- name: ...
  ...
  volumeMounts:
    - name: ...
      # path in container
      mountPath: ...

volumes:
- name: ...
  persistentVolumeClaim:
    claimName: myVolumeClaim
```

A `PersistentVolumeClaim` resource attaches a pod to a `PersistentVolume`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myVolumeClaim
spec:
  accessModes:
    ...
  storageClassName: <class name>
  resources:
    requests:
      storage: <required capacity>
```

And a `PersistentVolume` resource is a shared volume which abstracts a storage backend:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ...
spec:
  capacity:
    storage: ...
  accessModes:
    ...
  <storageClass>
```

`storageClass` properties depend on the storage class (backend) type.
It can be NFS, a cloud provider backend, ...

==== hostPath Volume

`hostPath` is a volume type. It is local storage which is not shared across the nodes in the cluster, which makes it not recommended.

```yaml
containers:
- name: ...
  ...
  volumeMounts:
    - name: ...
      # path in container
      mountPath: ...

volumes:
- name: ...
  hostPath:
    path: ...
```

==== NFS Volume

Network File System (NFS) is a distributed file system protocol which allows to store data on a remote server and interact with it as if it were local.

First, you need to create a `PersistentVolume` resource:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: myNfsVolume
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  nfs:
    server: <ip>
    path: <path>
```

#colorbox([The accessModes are storage class dependent and application dependent.], title: "Note")

Next, create a Persistent volume claim to allow pods to access the volume:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myNfsVolume
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 10Gi
```

#colorbox([This claim says that we require any nfs storage that has at least 10Gi of capacity.], title: "Note")

Then, use the volume claim in a deployment:

```yaml
containers:
- name: ...
  ...
  volumeMounts:
    - name: myNfsVolumeClaim
      # path in container
      mountPath: ...

volumes:
- name: myNfsVolumeClaim
  persistentVolumeClaim:
    claimName: myNfsVolume
```

=== Replicas

Pods can be run as replicas to substitute stopped pods.

A service can connect the replicas together to handle the load balancing
for high availability.

This doesn't work for stateful pods, such as databases: you need to use the  StatefulSet component.

=== StatefulSet

A StatefulSet is like a deployment, but for stateful applications.


== Configuration files

All components declared in a configuration file can have `labels`,
which are (key, value) pairs attached to that resource.
These labels are identifiers.

It is useful, for example, to match all the pods replicas that have the same label.

To apply a configuration file, use the apply command:

```sh
kubectl apply -f <file>
```

== Helm Package Manager

Helm (https://helm.sh) is a package manager for Kubernetes.

Helm defines Helm charts, which are templates for Kubernetes resources.

To find helm charts, you can search for them on artifacthub (https://artifacthub.io/).

On a package website, you can:

- click on "templates" to view the templates files
- click on "default values" to view all the values that can be customized

First, you need to add a repository using:

```sh
helm repo add <name> <url>
```

To install a package (with default values) use:

```sh
helm install <name> <repo name>/<chart name>
```

To install a package with overridden default values:

1. Check the default values of the package
2. Create a yaml file with the customized values:

  ```yaml
  keyName1: value1
  keyName2: value2
  ...
  ```
3. Install the package using the following command:

  ```sh
  helm install <name> <repo name>/<chart name> --values=<file.yml>
  ```

To view a list of all the installed charts, use:
```sh
helm ls
```

To upgrade a chart or make changes to the values:
```sh
helm upgrade <name> <repo name>/<chart name> --values=<file.yml>
```

Changes are saved as "releases", which can be used to rollback:
```sh
helm rollback <name> <revision number>
```

A history of changes can be viewed using:
```sh
helm history <name>
```

== Cert Manager

Cert Manager allows to manage SSL certificates in Kubernetes.

Certificates must also be renewed.

Cert Manager stores certificates in Secrets.

When you install Cert Manager, you also need to install CustomResourceDefinitions,
which are new kinds of resources that are specific to cert manager:

- `Issuer`: represents a certificate authority, which generates and issues certificates.
  
  An issuer only works in one namespace.

- `ClusterIssuer`: like the Issuer, but works in multiple namespaces.

Then you create a `Certificate` resource:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: <resource name>
  namespace: <namespace>
spec:
  # where the certificate is stored
  secretName: <name>
  issuerRef:
    name: <name of issuer>
    # set kind to Issuer or ClusterIssuer
    kind: ClusterIssuer
  dnsNames:
  - <dns name>
```

To view information about the current status:

```sh
kubectl describe certificate -n <namespace>
kubectl get certificaterequest
kubectl describe certificaterequest
```

To use the certificate, change the `Ingress` resource:

```yaml
apiVersion: ...
kind: Ingress
metadata:
  name: ...
  namespace: ...
spec:
  rules:
  - host: <host name>
    http:
      ...

  tls:
  - hosts:
      - <host name>
    secretName: <secret name>
```

The `tls` section is used to refer to the certificate.

== GitOps

GitOps is the practice of hosting resource files using a git repository
and have a management tool that listens to changes to apply them automatically.

=== Portainer

Portainer is a web UI interface for managing Docker and Kubernetes,
but it also allows to perform GitOps.

=== ArgoCD

ArgoCD allows to deploy applications using GitOps.

== Useful kubectl commands

Shows all resources except for `ConfigMap`s and `Secret`s:
```sh
kubectl get all
```

Shows all the `ConfigMap`s:
```sh
kubectl get configmap
```

Shows all the `Secret`s:
```sh
kubectl get secret
```

Shows details about a resource:
```sh
kubectl describe <resource_type> <resource_name>
```

Shows all the logs of a pod:
```sh
kubectl logs <pod_name> [-f]
```

List all the nodes in the cluster:
```sh
kubectl get nodes
```

Open an interactive bash shell inside a pod:
```sh
kubectl exec -it <pod name> -- /bin/bash
```
