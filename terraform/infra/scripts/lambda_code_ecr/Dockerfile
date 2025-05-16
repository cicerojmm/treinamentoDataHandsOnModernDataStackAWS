FROM public.ecr.aws/lambda/python:3.9

# Copia requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Instala dependências Python
RUN pip install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.txt

# Copia o código do Lambda
COPY . ${LAMBDA_TASK_ROOT}/

# Define o handler (nome do arquivo.nome_da_função)
CMD [ "lambda_handler.lambda_handler" ]
