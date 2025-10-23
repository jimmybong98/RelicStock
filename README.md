# RelicStock

Aplicativo completo para gestão de estoque composto por frontend Flutter e backend FastAPI em Python.

## Estrutura do projeto

```
backend/              # API FastAPI com SQLAlchemy e geração automática do banco SQLite
flutter_app/          # Aplicativo Flutter com layout escuro inspirado no design fornecido
```

## Backend (Python)

O backend usa FastAPI, SQLAlchemy e SQLite (arquivo `relicstock.db`). As tabelas são criadas automaticamente no evento de inicialização da API.

### Instalação

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
cd ..
```

### Execução

```bash
uvicorn backend.main:app --reload
```

A API ficará disponível em `http://127.0.0.1:8000`.

### Recursos principais

- **Armários**: cadastro e listagem de endereços de armazenamento (`/lockers`).
- **Itens**: CRUD, movimentações de entrada/saída, geração de QR Code em base64 (`/items`).
- **Movimentações**: registro de baixa ou reposição de estoque (`/items/{id}/movements`).
- **Solicitações de compra**: criação e atualização de status (`/purchase-requests`).
- **Dashboard**: resumo com totais, itens em alerta e solicitações pendentes (`/snapshot`).

## Frontend (Flutter)

O app Flutter segue o layout escuro do print fornecido, utilizando Navigation Rail para navegar entre os módulos (Visão geral, Itens, Armários e Solicitações).

### Dependências

Certifique-se de ter o SDK Flutter 3.13+ instalado.

### Execução

```bash
cd flutter_app
flutter pub get
flutter run -d chrome  # ou outro dispositivo disponível
```

### Principais telas

- **Dashboard**: métricas de estoque.
- **Itens**: cadastro, baixa/entrada de estoque, geração de QR codes e visualização de endereço do armário.
- **Armários**: gerenciamento dos endereços físicos do estoque.
- **Solicitações**: fluxo para registrar e atualizar pedidos de compra.

O aplicativo consome diretamente a API Python (`http://localhost:8000`). Ajuste o `baseUrl` em `flutter_app/lib/services/api_service.dart` caso execute o backend em outro host/porta.

## Banco de dados

O banco padrão é um arquivo SQLite criado automaticamente (`backend/relicstock.db`). Para resetar os dados basta excluir o arquivo com a API parada.

## Testes

- Backend: utilize ferramentas como `pytest` ou `httpie`/`curl` para validar os endpoints.
- Frontend: execute `flutter test` para validar widgets e lógicas (nenhum teste foi incluído nesta versão inicial).

## Licença

Projeto criado para demonstrar o fluxo completo do sistema de inventário RelicStock.
