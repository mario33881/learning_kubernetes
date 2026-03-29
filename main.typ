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

It groups together the containers of an application.

Kubernetes allows:

- scalability: increase/decrease the resources depending on CPU usage, number of requests, ...
- self-healing: it restarts containers if they stop running.
- service discovery and load balancing: a DNS name is shared by a set of pods.
- automated rollouts and rollbacks of changes that propagate gradually.
- storage orchestration by mounting the storage.
- secrets and configuration management.
- automatic bin packing: chooses where to run containers based on requirements and constraints.


== Installation

To install Kubernetes, you first need the `kubectl` CLI tool, which is used to interact with the Kubernetes cluster.

Then, to run a local instance of Kubernetes to learn to use it, install minikube.

#colorbox([`kubectl` works on all types of Kubernetes clusters.], title: "Note")


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

  It is used by the dashboard and the kubectl tool to manage new configurations (in YAML or JSON format).

- `etcd`: database (key, value) with the Kubernetes configuration.
- `kube-scheduler`: schedules new pods to worker nodes depending on the resources that are available.
- `kube-controller-manager`: runs controllers, which are used to move the system to the desired state.
- `cloud-controller-manager`: used to integrate with a cloud provider. 

=== Worker Nodes

Nodes maintain running pods (with the applications running inside of them).

They have the following components:

- `kubelet`: ensures that the pods are running
- `kube-proxy`: it handles network rules to implement services (exposed applications)
- Container runtime: used to run the containers


== Concepts

=== Pod

A pod is a group of containers, logically grouped together for management purposes.
Tipically, one pod contains one container with one application.

Each pod gets its own internal IP address, which changes every time the pod restarts.

By default, containers in a pod can't be accessed from outside the cluster's virtual network. To expose the pod, it must become a "Service".

Pods are ephemeral, like docker containers: they don't store permanent state/data themselves.

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

  The pod's `spec` contains the `containers` specification, with its image and port number.

The file also contains another component which is not managed by the user, which is the current state.

#colorbox([The state is contained inside etcd.], title: "Note")

```yaml
apiVersion: v1
kind: Deployment
metadata:
  name: myDeployment
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
      container:
      - name: myContainer
        image: myImage:<version>
        ports:
        - containerPort: <port>
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
```

The `selector` indicates that all the replicas that match the labels are part of the same deployment.

`valueFrom/secretKeyRef` is used to retrieve data from a `Secret`. Its `name` is the name of the `Secret`, while `key` is the name of the key which contains the secret itself.

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
spec:
  type: NodePort
  selector:
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

=== Ingress

Forwards requests to a service.
It is useful for setting up HTTPS and accessing the service using a URL instead of an IP.

=== ConfigMap

It is an external configuration to the application, stored in plain text.
It avoids having to build a new container if, for example, an URL must be changed.

It can contain URLs which are connected to the pod.

Can be accessed as environment variables or as a properties file.

==== Configuration File

A ConfigMap configuration file has:

- An apiVersion with the configuration version.
- kind set as `ConfigMap`.
- metadata, such as the `name` of the ConfigMap.
- data: it contains (key, value) pairs of data.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myConfigMap
data:
  key1: value1
  key2: value2
```

=== Secret

It is a special ConfigMap, used for storing secrets.
By default, it stores data using base64, but it is meant to be used with external services to encrypt the data.

They can be connected to a pod, which can use the data.

Can be accessed as environment variables or as a properties file.

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

=== Volume

Used for persistent data storage.
It attaches storage to the pod, which can be local or remote storage.

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
