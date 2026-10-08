RetroRay

Um pequeno ray tracer baseado em CPU, escrito em C, criado como um experimento de computação gráfica 3D leve e inspirado na computação dos anos 90.

O RetroRay calcula a renderização diretamente pela CPU, sem utilizar APIs gráficas, engines ou frameworks externos. A imagem final é gerada no formato PPM, mantendo a implementação simples, portátil e fácil de estudar.

Estado atual

O RetroRay está em sua primeira versão funcional.

Atualmente, o projeto possui:

- Ray tracing por CPU
- Esferas 3D
- Interseção entre raios e esferas
- Vetores 3D
- Produto escalar
- Normalização de vetores
- Iluminação Lambertiana
- Luz ambiente
- Até 10 esferas por cena
- Cor de fundo configurável
- Interface de comandos pelo terminal
- Renderização em 640×480
- Exportação de imagens no formato PPM P6

Filosofia

O RetroRay foi criado com uma proposta simples:

«Explorar computação gráfica 3D utilizando o mínimo possível de recursos e dependências.»

O projeto não utiliza OpenGL, DirectX, Vulkan, SDL ou uma engine gráfica.

Toda a parte fundamental do ray tracing é implementada diretamente em C, incluindo os cálculos matemáticos necessários para determinar as interseções e a iluminação dos objetos.

A resolução de 640×480 também foi escolhida como referência à computação gráfica dos anos 90.

Como funciona

Para cada pixel da imagem, o RetroRay calcula um raio partindo da câmera em direção à cena.

Quando o raio encontra uma esfera, o programa calcula:

1. A distância até a interseção.
2. A posição do ponto atingido.
3. A normal da superfície.
4. A intensidade da iluminação.
5. A cor final do pixel.

O processo é repetido para todos os pixels da imagem.

A imagem resultante é gravada diretamente em um arquivo PPM.

Comandos

Ao executar o programa, uma interface simples de terminal é apresentada.

Adicionar uma esfera

esfera X Y Z Raio R G B

Exemplo:

esfera 0 0 -5 1 255 0 0

Isso adiciona uma esfera vermelha à cena.

Alterar o fundo

fundo R G B

Exemplo:

fundo 20 20 40

Renderizar

render

A cena será renderizada em:

640 × 480

e salva como:

cena_90s.ppm

Limpar a cena

limpar

Remove todas as esferas da cena.

Sair

sair

Encerra o programa.

Exemplo

Uma cena simples pode ser criada com:

3D_Prompt> esfera 0 0 -5 1 255 0 0
3D_Prompt> esfera 2 0 -6 1 0 255 0
3D_Prompt> esfera -2 0 -6 1 0 0 255
3D_Prompt> render

O resultado será salvo em:

cena_90s.ppm

Requisitos

O RetroRay foi desenvolvido para utilizar poucos recursos.

Software

- Compilador C compatível com o código utilizado pelo projeto
- Biblioteca matemática ("libm", quando necessária)

Hardware

Não é necessária uma GPU.

A renderização é realizada inteiramente pela CPU.

A quantidade de memória utilizada pelo programa é pequena, pois a cena atual possui um limite de 10 esferas e a imagem é escrita progressivamente no arquivo.

«A compatibilidade com sistemas operacionais e computadores antigos depende do compilador e da forma como o programa é compilado. Compatibilidade com uma versão específica do Windows ou outro sistema deve ser considerada experimental até ser testada.»

Formato da imagem

O RetroRay utiliza o formato:

PPM P6

O PPM foi escolhido por sua simplicidade e por permitir que o programa escreva os dados da imagem diretamente, sem precisar de uma biblioteca externa para formatos gráficos mais complexos.

Limitações atuais

A versão atual é deliberadamente pequena e possui algumas limitações:

- Apenas esferas podem ser adicionadas.
- Existe um limite de 10 objetos.
- Não há sombras.
- Não há reflexos.
- Não há refração.
- Não há texturas.
- Não há modelos 3D externos.
- Não há aceleração por GPU.
- Não existe uma interface gráfica.
- A renderização é feita exclusivamente pela CPU.

Essas limitações fazem parte do estágio atual do projeto.




Licença

Este projeto é distribuído sob a licença definida no arquivo "LICENSE".

Objetivo

O RetroRay é principalmente um projeto experimental e educacional.

Seu objetivo é explorar como um ray tracer 3D pode ser construído a partir de componentes básicos, mantendo o código pequeno, compreensível e independente de grandes frameworks.

---

RetroRay
Ray tracing simples. C puro. CPU. PPM. Sem uma GPU para fazer todo o trabalho pesado.