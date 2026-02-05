# 💊 Lembrete de Remédios

App mobile desenvolvido em Flutter para ajudar no controle e lembrete de medicamentos.

## 📱 Funcionalidades

- ✅ Cadastro de medicamentos com nome e dosagem
- ✅ Definição de múltiplos horários para cada medicamento
- ✅ Notificações push nos horários programados
- ✅ Notificações funcionam mesmo com app fechado
- ✅ Lista de medicamentos cadastrados
- ✅ Exclusão de medicamentos
- ✅ Persistência local dos dados (SQLite)

## 🛠️ Tecnologias Utilizadas

- **Flutter 3.38.7**
- **Dart 3.10.7**
- **SQLite** (sqflite) - Banco de dados local
- **Flutter Local Notifications** - Sistema de notificações
- **Material Design 3** - Interface moderna

### Principais Dependências

```yaml
flutter_local_notifications: ^17.2.3
sqflite: ^2.3.3+2
path_provider: ^2.1.5
intl: ^0.19.0
timezone: ^0.9.4
```

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                          # Inicialização do app
├── models/
│   └── medicamento.dart              # Model de medicamento
├── database/
│   └── database_helper.dart          # Gerenciamento do SQLite
├── screens/
│   ├── home_screen.dart              # Tela principal
│   └── add_medicamento_screen.dart   # Tela de cadastro
├── services/
│   └── notification_service.dart     # Serviço de notificações
└── widgets/
    └── medicamento_card.dart         # Card de exibição
```

## 🚀 Como Executar

### Pré-requisitos

- Flutter SDK 3.x ou superior
- Android Studio / VS Code
- Dispositivo Android ou Emulador

### Passos

1. Clone o repositório:

```bash
git clone https://github.com/cristopherlima-dev/lembrete-remedios.git
cd lembrete_remedios
```

2. Instale as dependências:

```bash
flutter pub get
```

3. Execute o app:

```bash
flutter run
```

## ⚙️ Configurações Android

O app requer as seguintes permissões (já configuradas no AndroidManifest.xml):

- `SCHEDULE_EXACT_ALARM` - Alarmes exatos
- `POST_NOTIFICATIONS` - Enviar notificações
- `RECEIVE_BOOT_COMPLETED` - Manter alarmes após reiniciar

**Nota:** Em alguns dispositivos (Xiaomi, Samsung, Huawei), pode ser necessário desabilitar a otimização de bateria para o app nas configurações do sistema.

## 📝 Como Usar

1. **Adicionar Medicamento:**
   - Toque no botão `+` na tela inicial
   - Preencha o nome do medicamento
   - Adicione a dosagem (opcional)
   - Adicione um ou mais horários
   - Salve o medicamento

2. **Notificações:**
   - As notificações aparecerão automaticamente nos horários programados
   - Funcionam mesmo com o app fechado
   - Repetem diariamente

3. **Excluir Medicamento:**
   - Toque no ícone de lixeira no card
   - Confirme a exclusão

## 📄 Licença

Este projeto está sob a licença MIT.

---

**Versão:** 1.0.0  
**Data:** Fevereiro 2026  
**Status:** Em desenvolvimento ativo 🚧
