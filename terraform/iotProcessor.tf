locals {
  ssmParameterNameIotConnectionString = "/${local.deploymentName}/iotConnectionString"
  ssmParameterNameStorageAccountConnection = "/${local.deploymentName}/storageAccountConnectionString"
}

resource azurerm_storage_account processorStorageAccount {
  name = lower(replace(local.deploymentName,"-",""))
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location = azurerm_resource_group.resourceGroup.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
}

resource azurerm_iothub_shared_access_policy iotProcessorSharedAccessPolicy {
  iothub_name = azurerm_iothub.iotHub.name
  name = "iotProcessor"
  service_connect = true
  resource_group_name = azurerm_iothub.iotHub.resource_group_name  
}

resource azurerm_iothub_consumer_group iotProcessorConsumerGroup {
  name = "iotProcessor"
  eventhub_endpoint_name = "events"
  iothub_name = azurerm_iothub.iotHub.name
  resource_group_name = azurerm_iothub.iotHub.resource_group_name
}

resource aws_ssm_parameter iotConnectionString {
  name = local.ssmParameterNameIotConnectionString
  type = "SecureString"
  value = "Endpoint=${azurerm_iothub.iotHub.event_hub_events_endpoint};SharedAccessKeyName=${azurerm_iothub_shared_access_policy.iotProcessorSharedAccessPolicy.name};SharedAccessKey=${azurerm_iothub_shared_access_policy.iotProcessorSharedAccessPolicy.primary_key}"
  tags = {
    deploymentName = local.deploymentName
  }
}

resource aws_ssm_parameter storageAccountKey {
  name = local.ssmParameterNameStorageAccountConnection
  type = "SecureString"
  value = azurerm_storage_account.processorStorageAccount.primary_access_key
  tags = {
    deploymentName = local.deploymentName
  }
}

resource aws_ecs_cluster ecsCluster {
  name = local.deploymentName
  tags = {
    deploymentName = local.deploymentName
  }
}

resource aws_iam_role ecsTaskRole {
  name = "${local.deploymentName}-ecsRole"
  assume_role_policy = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON
}

resource aws_iam_policy ecsTaskPolicy {
  name = "${local.deploymentName}-ecsPolicy"
  policy = <<JSON
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": [
        "${aws_ssm_parameter.iotConnectionString.arn}",
        "${aws_ssm_parameter.storageAccountKey.arn}"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource":"*"
    }
  ]
}
JSON
}

resource aws_iam_role_policy_attachment ecsRolePolicyAttachment {
  policy_arn = aws_iam_policy.ecsTaskPolicy.arn
  role = aws_iam_role.ecsTaskRole.name
}

resource aws_ecs_task_definition ecsTaskIotProcessor {
  family = local.deploymentName
  execution_role_arn = aws_iam_role.ecsTaskRole.arn
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  network_mode = "awsvpc"
  container_definitions = <<JSON
[
    {
      "name": "iotProcessor",
      "image": "yardbirdsax/iotprocessor",
      "memory": 64,
      "cpu": 10,
      "environment": [
        {
          "name":"event_hub_name",
          "value": "${azurerm_iothub.iotHub.event_hub_events_path}"
        },
        {
          "name":"storage_account_name",
          "value": "${azurerm_storage_account.processorStorageAccount.name}"
        },
        {
          "name":"storage_container_name",
          "value":"${local.deploymentName}"
        }
        
      ],
      "secrets": [
        {
          "name":"event_hub_connection_string",
          "valueFrom": "${aws_ssm_parameter.iotConnectionString.arn}"
        },
        {
          "name":"storage_account_key",
          "valueFrom": "${aws_ssm_parameter.storageAccountKey.arn}"
        }
      ],
      "logConfiguration": {
        "logDriver":"awslogs",
        "options":{
          "awslogs-create-group":"true",
          "awslogs-region":"us-east-2",
          "awslogs-group":"/ecs/${local.deploymentName}",
          "awslogs-stream-prefix":"${local.deploymentName}"
        }
        
      }
    }
]
JSON

  depends_on = [
    aws_iam_role_policy_attachment.ecsRolePolicyAttachment
  ]
  # tags = {
  #   deploymentName = local.deploymentName
  # }
}

resource aws_vpc ecsVpc {
  cidr_block = "192.168.250.0/24"
  tags = {
    deploymentName = local.deploymentName
    name = local.deploymentName
  }
}

resource aws_subnet ecsSubnet {
  cidr_block = "192.168.250.0/25"
  vpc_id = aws_vpc.ecsVpc.id
}

resource aws_internet_gateway gateway {
  vpc_id = aws_vpc.ecsVpc.id

  tags = {
    deploymentName = local.deploymentName
    name = local.deploymentName
  }
}

resource aws_route_table routeTable {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  vpc_id = aws_vpc.ecsVpc.id

  tags = {
    name = local.deploymentName
    deploymentName = local.deploymentName
  }
}

resource aws_route_table_association routeTableAssociation {
  route_table_id = aws_route_table.routeTable.id
  subnet_id = aws_subnet.ecsSubnet.id
}

resource aws_ecs_service ecsService {
  name = local.deploymentName
  cluster = aws_ecs_cluster.ecsCluster.arn
  task_definition = aws_ecs_task_definition.ecsTaskIotProcessor.id
  launch_type = "FARGATE"
  desired_count = 1
  network_configuration {
    subnets = [
      aws_subnet.ecsSubnet.id
    ]
    assign_public_ip = true
  }
  # tags = {
  #   deploymentName = local.deploymentName
  # }
}

