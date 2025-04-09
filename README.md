# DonateCrypto

O **DonateCrypto** é um contrato inteligente desenvolvido em Solidity que permite a criação e gestão de campanhas de doação em criptomoedas. Ele possibilita que usuários criem campanhas, façam doações e retirem os fundos arrecadados, além de permitir que o administrador do contrato retire as taxas acumuladas.

## Funcionalidades

- **Criação de campanhas**: Usuários podem criar campanhas com título, descrição, vídeo e imagem.
- **Edição de campanhas**: O autor de uma campanha pode editar suas informações enquanto ela estiver ativa.
- **Doações**: Qualquer usuário pode doar para campanhas ativas.
- **Retirada de fundos**: O autor de uma campanha pode retirar os fundos arrecadados, descontando uma taxa fixa.
- **Administração de taxas**: O administrador do contrato pode retirar as taxas acumuladas.

## Estrutura do Contrato

### Estruturas e Variáveis

- `Campaign`: Estrutura que representa uma campanha, contendo informações como autor, título, descrição, URL de vídeo e imagem, saldo, número de apoiadores e status.
- `donateFee`: Taxa fixa cobrada por campanha (100 wei).
- `nextId`: Identificador incremental para campanhas.
- `feesBalance`: Saldo acumulado das taxas.
- `admin`: Endereço do administrador do contrato.
- `campaigns`: Mapeamento de IDs para campanhas.

### Principais Funções

- `addCampaign`: Adiciona uma nova campanha.
- `editCampaign`: Permite que o autor edite uma campanha ativa.
- `getRecentCampaigns`: Retorna as 5 campanhas mais recentes.
- `donate`: Permite que usuários façam doações para uma campanha.
- `getSupporters`: Retorna o número de apoiadores de uma campanha.
- `withdraw`: Permite que o autor retire os fundos de uma campanha ativa.
- `adminWithdrawFees`: Permite que o administrador retire as taxas acumuladas.

## Requisitos

- Solidity 0.8.17 ou superior.
- Ambiente de desenvolvimento Ethereum (como Hardhat ou Remix).

## Como Usar

1. **Implantação do Contrato**:
   - Compile o contrato utilizando o compilador Solidity.
   - Faça o deploy do contrato em uma rede Ethereum.

2. **Interação com o Contrato**:
   - Use ferramentas como Remix, Hardhat ou uma interface personalizada para interagir com as funções do contrato.

3. **Configuração do Administrador**:
   - O endereço que fizer o deploy do contrato será automaticamente definido como administrador.

## Licença

Este projeto está licenciado sob a licença MIT. Consulte o cabeçalho do arquivo `DonateCrypto.sol` para mais detalhes.
