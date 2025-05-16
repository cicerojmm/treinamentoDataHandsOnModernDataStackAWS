# Scripts de Bootstrap

Este diretório contém scripts de bootstrap (user data) para inicialização de instâncias EC2.

## ec2_bootstrap.sh

Script de bootstrap para configurar uma instância EC2 com ferramentas para trabalhar com a Modern Data Stack na AWS.

### Funcionalidades

- Instalação de ferramentas básicas (git, wget, unzip, python3, pip, jq)
- Instalação do AWS CLI v2
- Instalação do Docker e Docker Compose
- Instalação do Node.js e NPM
- Instalação de bibliotecas Python para data engineering
- Configuração de um produtor Kinesis para testes
- Criação de documentação para o usuário

### Variáveis de template

O script usa as seguintes variáveis que são substituídas pelo Terraform:

- `${kinesis_stream_name}`: Nome do Kinesis Stream
- `${aws_region}`: Região AWS
- `${opensearch_dashboard_endpoint}`: Endpoint do dashboard do OpenSearch Serverless

### Como usar

O script é carregado no Terraform usando a função `templatefile`:

```hcl
user_data = templatefile("${path.module}/bootstrap/ec2_bootstrap.sh", {
  kinesis_stream_name = module.kinesis_stream.stream_name,
  aws_region = var.region,
  opensearch_dashboard_endpoint = module.opensearch_serverless.dashboard_endpoint
})
```