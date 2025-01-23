#OBJETIVO:
#Crear recursos AWS definidos; una instancia VM que tenga instalado un Web Server NGINX, además, agregar a la instancia
# un recurso SSH para conectarse y además, un firewall o security group con ingresos a los puertos 80y 22, y egresos
# o salidas a todos los puertos.
#
#CONSIDERAR:
#Deberia existir un usuario en AWS con accesos FULL o RunInstances,DescribeInstances y TerminateInstances EC2,
# el cual este configurado en la maquina que corre Terraform (en /User/a.astorga/.aws/credencials) y con el ID/clave
# acceso que fue creado el usuario en AWS. Sólo así funciona...
#
### Provider a usar aws / cada providers tiene su propia definicion, puede variar
provider "aws" {
  region    = "us-east-1"   # Cambiar por region que uses
#  profile   = "default"     # 0 el nombre del perfil configurado
}

### resource instance aws
resource "aws_instance" "nginx_server" {
  ami             = "ami-0440d3b780d96b29d"
  instance_type   = "t3.micro"

  # Instalar NGINX, usando script de AWS user_data, que corre cuando se reinicia una VM.
  # En este caso, se crea la VM y luego este script instala y habilita NGINX
  user_data = <<-EOF
            #!/bin/bash
            sudo yum install -y nginx
            sudo systemctl enable nginx
            sudo systemctl start nginx
            EOF

  #Asociar a la instancia creada, la clave ssh que se creara en el sgte recurso
  key_name = aws_key_pair.nginx-server-ssh.key_name

  #Agregar recurso security group o firewall a la vm
  vpc_security_group_ids = [
    aws_security_group.nginx-server-sg.id
  ]

  tags = {
    Name = "bginx-server-test"
    Environment = "Test"
    Owner = "angeloastorga@gmail.com"
    Team = "Devops"
    Project = "Lo que diga tu corazon"
  }
}

# Crear y usar clave ssh en la local y subir a AWS
# % ssh-keygen -t rsa -b 2048 -f "nginx-server.key"
resource "aws_key_pair" "nginx-server-ssh" {
    key_name = "nginx-server-ssh"
    public_key = file("nginx-server.key.pub")  #ruta donde esta file key publica
    
    tags = {
        Name = "bginx-server-ssh"
        Environment = "Test"
        Owner = "angeloastorga@gmail.com"
        Team = "Devops"
        Project = "Lo que diga tu corazon"
    }

}

# Crear security group o firewall, con ingresos port 22 ssh y 80 http, y egresos TODO
resource "aws_security_group" "nginx-server-sg" {
    name = "nginx-server-sg"
    description = "grupo seguridad permite accesos SSH y HTTP"
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Todo
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Todo
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"          # Todos
        cidr_blocks = ["0.0.0.0/0"] # Todos
    }
    
    tags = {
        Name = "bginx-server-sg"
        Environment = "Test"
        Owner = "angeloastorga@gmail.com"
        Team = "Devops"
        Project = "Lo que diga tu corazon"
    }
}
  
# Uso de OUTPUT, acá o por archivo .tf 
output "server_public_ip" {
  description = "Direccion IP publica server nginx"
  value       = aws_instance.nginx_server.public_ip
}

output "server_public_dns" {
  description = "Direccion IP publica server nginx"
  value       = aws_instance.nginx_server.public_ip
}

# TIPS:
# El archivo "terraform.tfvars" que es el Default, inicializa los valores de las variables a utilizar, 
#   luego en el archivo variables.tf se definen las variables para luego ser usadas.
# Para usar distintos archivos .tfvars, se deben crear y luego llamar con (% tf plan --var-files=qa.tfvars)
# Para generar un archivo de Plan automatico y que no pida confirmaciones, puedes generar un
#   plan hacia un archivo (% tf plan -out server_qa.tfplan) y luego, solo usarlo (% tf apply "server_qa.tfplan")
#