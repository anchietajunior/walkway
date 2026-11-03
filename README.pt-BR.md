# Walkway

[English](README.md)

Walkway é uma coleção de skills do Claude Code que entrega uma issue do Linear em três estágios, Planning, Development e Verification, executados por seis agentes. Cada agente tem uma responsabilidade, um contrato e uma persona, e roda na sua própria sessão do Claude Code. O Coordinator inicia cada agente como um worker do Orca, um por vez, acompanha cada agente e cada documento, e termina com um draft PR que leva as evidências. O Coordinator só coordena: ele nunca altera código, e todo build, teste e alteração de código roda num agente. O usuário participa só das decisões estratégicas.

```text
Planning -> Development -> Simplifier -> Code Reviewer -> Verification -> draft PR
                 ^                             |                |
                 +---- code-review-findings ---+                |
                 +---- verification-findings -------------------+
```

Os termos usados aqui estão definidos em [GLOSSARY.md](GLOSSARY.md) (em inglês). As decisões por trás do desenho estão em [docs/adr/](docs/adr/).

## Como uma Task anda

1. Você pede ao Grok Bot para iniciar a issue, ou roda o comando de [Iniciar uma Task](#iniciar-uma-task). O Orca cria um Workspace para a issue e inicia o Coordinator com `/loop /walkway`.
2. O Coordinator dá ao Workspace o nome `<ISSUE-ID> <título da issue>`, cria a pasta da Task `.walkway/tasks/<ISSUE-ID>/` e inicia o Planning.
3. O Planning lê a issue e os Resources e escreve o `tech-spec.md`. A sessão dele fecha, o Coordinator confere a tech spec e inicia o Development.
4. O Development escreve o código e os testes, faz o commit, roda os Local Checks e escreve o `development-1.md`. Depois o Simplifier deixa a mudança mais simples, e o Code Reviewer faz os dois reviews. Isso é o ciclo 1.
5. Quando o `code-review-findings.md` lista um finding, o Coordinator inicia uma nova sessão de Development com esse arquivo, e o ciclo 2 roda Development, Simplifier e Code Reviewer de novo.
6. Quando ele não lista nenhum, a Verification confere o código contra a tech spec, como descreve [Verification em detalhe](#verification-em-detalhe). Um finding em `verification-findings.md` inicia um novo ciclo da mesma forma.
7. Quando a Verification passa, o Coordinator abre o draft PR, move a issue do Linear para o estado de review e escreve a retrospectiva.
8. Depois de cada agente, o Coordinator diz qual agente terminou, o resultado e o próximo agente. Você responde só às Escalations.

## Agentes

Cada agente tem exatamente o nome abaixo, no Orca e em todo arquivo do Walkway.

| Estágio | Agente | Persona | Resultado | Próximo |
| --- | --- | --- | --- | --- |
| | Coordinator | Tech lead | Todos os agentes iniciados, acompanhados e verificados; o andamento reportado ao usuário; o draft PR | |
| Planning | Planning | Product manager e engenheiro sênior | A tech spec: metade negócio, metade tecnologia | Development |
| Development | Development | Engenheiro sênior pragmático que odeia overengineering; DHH em código Rails | Código e testes para a tech spec ou para os findings, com commit e Local Checks verdes | Simplifier |
| Development | Simplifier | Engenheiro pragmático com olhar novo; Vladimir Dementyev em código Rails | O mesmo comportamento, com menos mudanças e código mais fácil de ler | Code Reviewer |
| Development | Code Reviewer | Staff engineer independente | Dois reviews numa sessão e o `code-review-findings.md` | Development com findings, senão Verification |
| Verification | Verification | Engenheiro de verificação e de QA | A tech spec confrontada com o código, verificação formal, prova na aplicação rodando e o `verification-findings.md` | Development com findings, senão Coordinator |

Cada agente escreve o próximo agente no seu report, e o Coordinator inicia esse agente. Nenhum agente inicia outro: no Orca, o agente que inicia um worker precisa ficar vivo até esse worker reportar, então uma cadeia de agentes manteria vivas todas as sessões da cadeia.

### Coordinator

O Coordinator delega e acompanha o fluxo inteiro. Ele inicia cada agente, confere o resultado contra o gate do agente, segue para o agente que o report nomeia, responde às perguntas a partir dos Resources e leva ao usuário só as Escalations. Depois de cada gate, ele diz ao usuário numa linha qual agente terminou, o resultado e o próximo agente.

### Planning

O Planning age como um product manager experiente que também conhece o código. Ele cria ou corrige o Product Context, lê a issue do Linear, que é o seu primeiro Resource, e cada Resource listado em `.walkway/resources.md`, como páginas do Notion, projetos do Linear e documentação. Ele remove as ambiguidades, confronta cada suposição com o código e escreve a tech spec, o contrato da Task:

- **Business**: objetivo, customers e seus fluxos, Acceptance Criteria numerados, fora de escopo.
- **Technology**: o que já existe no código, design por área de código e fluxo de dados, Contracts (schema, APIs, jobs, flags, emails), estratégia de teste por AC, riscos.
- **Decisions**, cada uma com a sua evidência.

A tech spec diz o que muda e quais interfaces se mantêm; nomes e forma do código ficam com o Development.

### Development

O Development implementa a tech spec com a mudança correta mais simples, seguindo as regras do projeto. Ele escreve código chato, pelas [Readability rules](skills/walkway/readability-rules.md), para que o próximo agente ou humano entenda na primeira leitura: nomes nas palavras do domínio, pontos de entrada que leem como passos com nome, dados com partes nomeadas, e abstrações só para uma necessidade concreta. As Readability rules valem para qualquer linguagem; as regras de uma linguagem, de um framework ou de estilo, como comentários e assinaturas de tipo, vêm das regras do próprio projeto, que ganham sempre que as duas cobrem o mesmo ponto. Cada Acceptance Criterion recebe um teste de exemplo e, quando a propriedade dele precisa, um teste com entradas geradas, pelas [Property rules](skills/formal-verification/properties.md). Em código Rails, o Development pensa como DHH. Em código React e GraphQL, ele constrói cada peça do jeito que o projeto já constrói as vizinhas.

Num ciclo de correção, uma nova sessão de Development recebe um arquivo de findings e trata esse arquivo com o `receiving-code-review` do Superpowers: ela confere cada finding antes de agir, e então corrige ou rejeita com evidência. Um finding da Verification é confrontado com a tech spec; quando a própria tech spec está errada, o Development abre uma Escalation em vez de alterar a spec.

### Simplifier

O Simplifier abre uma sessão nova com a tech spec e a mudança do Development, e faz duas perguntas: "Se eu pudesse refazer esta implementação de um jeito mais simples e pragmático, com menos mudanças, sem mudar o comportamento e sem criar bugs, eu faria?" e "Cada método alterado passa na primeira leitura?". Ele aplica cada simplificação e reescreve cada método que não passa na primeira leitura. Ele roda em todo ciclo, logo depois do Development. Em código Rails, ele pensa como Vladimir Dementyev, autor de Layered Design for Ruby on Rails Applications.

### Code Reviewer

Uma sessão de Code Reviewer faz dois reviews, um depois do outro: o [`ce-code-review`](https://github.com/EveryInc/compound-engineering-plugin) do Compound Engineering (personas de review para correção, testes, manutenção e padrões do projeto, mais segurança, performance ou confiabilidade quando a mudança mexe nisso), e depois o [`requesting-code-review`](https://github.com/lucianghinda/superpowers-ruby) do Superpowers (qualidade de código, arquitetura, testes, requisitos e prontidão para produção). Ele roda cada persona e cada reviewer sozinho, sem subagent. Os findings Critical e Required vão para o `code-review-findings.md`, que uma nova sessão de Development recebe; os findings Optional e Nit viram sugestões no PR. Sem nenhum finding listado, o fluxo segue para a Verification.

### Verification

A Verification confronta a tech spec com o código que o Development, o Simplifier e o Code Reviewer produziram. Ela lê os reports desses agentes só para ver as respostas deles aos findings dela, porque esses reports são afirmações; a verdade é a tech spec. Ela rastreia cada AC, Contract, Decision e arquivo alterado entre a tech spec e o código, e depois verifica a mudança formalmente com a skill [`formal-verification`](skills/formal-verification/SKILL.md). Por fim, ela prova cada Acceptance Criterion na aplicação rodando, com screenshots de tudo que um customer vê. Cada divergência vai para o `verification-findings.md`, que uma nova sessão de Development recebe; sem nenhum finding listado, o Coordinator entrega. [Verification em detalhe](#verification-em-detalhe) explica cada verificação.

### Mocks

Algumas issues trazem um Mock: uma imagem da UI desejada. As ferramentas de Mock não têm a configuração da aplicação, então o Walkway reproduz o Mock o mais perto que as regras de front-end da aplicação permitem, nunca pixel por pixel. O Mock decide estrutura, conteúdo e hierarquia; os componentes, tokens e padrões das telas que já existem decidem os valores exatos. Cada desvio nomeia a regra que o causou, e a Verification compara cada tela com o seu Mock lado a lado. As regras estão em [skills/walkway/mocks.md](skills/walkway/mocks.md).

## Verification em detalhe

### Por que ela existe

Os testes conferem os casos que alguém escreveu. Um code review lê o código. Nenhum dos dois mostra que o código cumpre cada promessa da tech spec, em todos os casos. A Verification começa pela tech spec, trata o código como uma afirmação e só aceita uma promessa com evidência que ela mesma produziu, no commit revisado.

### As verificações, em ordem

```text
tech-spec.md
  1. Rastreio      cada AC, Contract e Decision -> o código que implementa
  2. Propriedades  cada AC -> uma regra que uma máquina consegue conferir
  3. Testes        testes de exemplo e testes com entradas geradas, rodados com seeds registradas
  4. Cobertura     cada linha alterada roda num teste
  5. Mutação       quebrar o código de propósito; um teste precisa falhar
  6. Modelo        modelo TLA+ verificado pelo TLC, só para comportamento de risco
  7. Aplicação     cada AC usado como o customer usa, com screenshots
  8. Checks        os Local Checks de novo
  -> PASS: o Coordinator entrega | FAIL: o verification-findings.md vai para uma nova sessão de Development
```

1. **Rastrear a tech spec até o código.** Cada AC, Contract e Decision recebe o código que o implementa, e cada arquivo alterado recebe a área do Design que o explica. Uma promessa sem código, um código que entorta uma promessa, ou um código que nenhuma promessa explica é um finding.
2. **Escrever uma propriedade por AC.** Uma propriedade é o AC escrito como uma regra que uma máquina consegue conferir:
   - **Given (dado):** o estado antes, como "um customer com dois testes abertos";
   - **When (quando):** a ação, como "o job de hora em hora roda";
   - **Then (então):** o que o customer vê, como "um email que lista os dois testes";
   - **Invariant (invariante):** o que continua verdadeiro antes e depois, como "nenhum customer recebe um email vazio";
   - **Breaks if (quebra se):** uma mudança no código que tornaria a regra falsa.

   A Verification escreve a propriedade a partir do texto do AC, nunca a partir do código, para que um bug no código não contamine o resultado esperado.
3. **Auditar e rodar os testes.** Cada AC precisa de um teste de exemplo, com entradas fixas. Quando o texto do AC diz sempre, nunca, qualquer, cada ou todos, ou quando a entrada varia, ele também precisa de um teste com entradas geradas: um teste que cria 100 ou mais entradas aleatórias a partir de uma seed e confere a propriedade em cada uma. A Verification roda cada teste com entradas geradas duas vezes, com duas seeds que ela registra, para que qualquer falha possa ser reproduzida. Um teste que falta, ou que é mais fraco que a propriedade, é um finding.
4. **Medir a cobertura das linhas alteradas.** Cada linha executável que a Task alterou precisa rodar durante os testes dos ACs. Uma linha que nenhum teste roda é uma linha que nenhum teste protege. A Verification usa o módulo `Coverage` do próprio Ruby ou o relatório LCOV do test runner de JavaScript, então o projeto não ganha nenhuma dependência nova.
5. **Testar com mutantes.** Uma mutação é um pequeno bug que a Verification coloca de propósito no código alterado: ela nega uma condição, muda um limite de `<` para `<=`, troca `&&` por `||`, remove uma guarda, ou remove um save, um enqueue ou um envio de email. Depois ela roda os testes do AC e restaura o arquivo.
   - Um teste falha: a mutação foi **morta**, então os testes pegam esse bug.
   - Todos os testes passam: a mutação **sobreviveu**, então esse bug chegaria em produção. Ela vira um finding que nomeia o teste que falta, a não ser que a mudança não possa alterar nenhum comportamento (**equivalente**).
6. **Verificar o modelo do comportamento de risco (Layer 2).** Só quando a mudança tem passos ou atores que podem se intercalar ou se repetir, e mexe com concorrência, máquina de estados, retries, idempotência ou dinheiro. A próxima seção explica essa verificação.
7. **Provar cada AC na aplicação rodando.** A Verification inicia a aplicação a partir do Workspace e usa cada AC como o customer usa: abre a tela, chama o endpoint ou roda o job. Ela salva um screenshot de cada AC que um customer vê e testa os limites: entrada vazia, permissão que falta, uma falha, uma ação repetida.
8. **Rodar os Local Checks** de novo no commit revisado.

As verificações 2 a 5 são a **Layer 1** e rodam em toda Task. A verificação 6 é a **Layer 2**.

### TLA+, PlusCal e TLC

Os testes rodam o código real com as entradas e a ordem de eventos que alguém escolheu. Os bugs de concorrência e de retries se escondem numa ordem que ninguém escolheu: um job lê uma linha, um customer cancela, o job grava.

- **TLA+** (Temporal Logic of Actions) é uma linguagem, criada por Leslie Lamport, que descreve um sistema como estados e os passos que levam de um estado ao próximo. A Verification escreve um modelo pequeno do comportamento de risco, não da aplicação inteira: cada ator, como uma requisição, um job ou um retry, é um processo, e cada transação de banco ou comando SQL é um passo. Um comentário acima de cada passo nomeia o código que ele representa.
- **PlusCal** é uma sintaxe parecida com pseudocódigo que é traduzida para TLA+. A Verification usa PlusCal quando o comportamento lê como um algoritmo.
- **TLC** é o verificador de modelos do TLA+ (model checker). Ele parte do estado inicial, tenta todas as ordens possíveis dos passos de todos os atores, dentro de limites pequenos, como dois jobs e três retries, e confere as propriedades em cada estado que alcança. Quando uma propriedade quebra, o TLC mostra um **contraexemplo**: a sequência exata de passos que leva ao estado ruim. A Verification reconta essa sequência com as palavras do código e reproduz a sequência no código real. Uma sequência que o código real consegue seguir é um finding Critical.
- **Java:** o TLC é um programa Java, distribuído no `tla2tools.jar`. O Walkway precisa de Java só para a Layer 2.

O TLC reporta os **estados distintos** que conferiu, a **profundidade** (a maior sequência de passos) e, no fim, nenhuma violação ou a propriedade violada com o seu contraexemplo.

Um exemplo de uma Task real: um job de email de hora em hora conferia com uma query SQL que um customer tinha testes para reportar, e carregava esses testes com uma segunda query quando montava o email. O TLC conferiu 302.816 estados distintos e encontrou uma sequência de 14 passos em que um teste era cancelado entre as duas queries, e o customer recebia um email vazio. A Verification reproduziu a sequência no código real e confirmou o bug. Os testes e os dois code reviews não tinham encontrado esse bug.

O TLC prova o modelo, não o código, e só dentro dos limites do modelo. Os comentários que ligam cada passo ao código e a reprodução no código real mantêm o modelo preso ao código.

### O veredito

A Verification dá PASS só quando todo AC está provado, todo AC, Contract e Decision bate com o código, todo Local Check passa e o `verification-findings.md` diz `No findings.`. Um AC está provado quando a propriedade dele está escrita, os testes dele passam, os testes dele mataram pelo menos uma mutação, as linhas alteradas dele rodam, cada mutação sobrevivente tem uma justificativa e, quando a Layer 2 rodou, o modelo não encontrou violação.

A seção Evidence do PR traz uma linha com as métricas:

```text
Verification: 12/12 ACs proved, changed lines 35/35 covered, 26/26 probes killed, Layer 2 302,816 states, no violation
```

- **ACs proved:** os ACs que cumprem todas as condições acima, do total de ACs.
- **Changed lines covered:** as linhas executáveis alteradas que rodaram num teste, do total delas.
- **Probes killed:** as mutações que um teste pegou, das mutações que não são equivalentes. O número dá contexto; o gate é que nenhuma mutação sobreviva sem justificativa.
- **Layer 2:** os estados distintos que o TLC conferiu, ou `not triggered`.

As regras estão em [skills/formal-verification/](skills/formal-verification/SKILL.md), com [properties.md](skills/formal-verification/properties.md) e [model-checking.md](skills/formal-verification/model-checking.md); a pesquisa por trás delas está em [docs/research/](docs/research/).

## Limites

A skill de cada agente começa com um **Contract**: o que ele lê, o que ele escreve, quando ele termina e qual agente vem depois. O trabalho fora do contrato pertence a outro agente. O Coordinator aplica os limites que mantêm a máquina livre:

- **Um agente por vez.** No máximo duas sessões Claude de uma Task ficam vivas: a do Coordinator e a do agente que está rodando.
- **Uma sessão nova por execução.** Cada execução de agente é um worker novo do Orca, em todo ciclo, e termina logo depois de reportar. Os workers que terminam fecham; ninguém os mantém abertos.
- **Sem subagents.** Nenhum agente e nem o Coordinator inicia subagents, Workflows, agent teams ou outros workers. Quando uma skill pede subagents, o agente faz cada parte sozinho, uma depois da outra.
- **Execuções com limite.** Duas execuções por agente em cada ciclo, três ciclos por Task e cinco minutos por comando; mais do que isso precisa de uma Escalation.

## Princípios

- **As regras do projeto ganham.** Cada agente segue as regras que o projeto documenta: `CLAUDE.md` e `AGENTS.md` em todos os níveis, `.claude/rules/`, `CONTRIBUTING.md` e os documentos que eles apontam. Quando uma delas difere de uma skill do Walkway sobre código, testes, docs, commits ou como rodar o projeto, a regra do projeto ganha; o fluxo do Walkway continua como as skills dizem.
- **Palavras do domínio.** Tudo que o Walkway escreve, do código ao corpo do PR, chama customers, users e todo outro ator pelo seu papel, nunca de "pessoas".
- **Afirme, não pergunte.** Cada agente pesquisa a fundo os Resources e deduz as respostas, registrando cada dedução com a sua evidência. Uma pergunta com uma opção que o agente recomendaria é decidida com essa opção e listada no report final. Só uma Escalation, uma pergunta sem um padrão seguro que só o usuário pode decidir, chega ao usuário, pelo Coordinator, com as opções e uma recomendação. O Code Reviewer e a Verification só escalam para uma ambiguidade ou um risco muito grande, e cada Escalation dessas conta como um Planning gap.
- **Afirmações são conferidas, nunca aceitas.** Nenhum agente entrega trabalho enquanto os testes, linters, type checks ou qualquer outro check de CI do projeto falham localmente. O Development cria o `.walkway/checks.md` a partir da configuração de CI, com comandos limitados à Task, testes paralelos com limite e um teto de 5 minutos por comando. As suítes completas rodam no CI do PR. A Verification roda cada Local Check de novo no commit revisado e produz as suas próprias evidências.
- **Só o Development e o Simplifier alteram código de produto e testes.** O Planning, o Code Reviewer e a Verification deixam o Workspace como o receberam, a Verification restaurando cada mutação logo depois de rodar, e o Coordinator não altera código.
- **As evidências vão com o PR.** O corpo do PR segue o template de PR do projeto e acrescenta uma seção curta `Evidence`: uma linha por Acceptance Criterion com como a Verification provou, uma para os Local Checks, uma para os ciclos e as sugestões do Code Reviewer. Os screenshots entram só quando a Task muda o front-end: eles vão com os Mocks para a branch `walkway-evidence` e para a seção visual do template. Sem mudança de front-end, essa seção diz só "No UI change.".
- **Cada Task melhora a próxima.** Uma retrospectiva nomeia a causa raiz de cada nova execução, ciclo de correção e Escalation. As causas do projeto viram Lessons em `.walkway/lessons.md`, que cada agente seguinte segue; as causas nas skills do Walkway viram propostas no `improvements.md` deste repositório, para o usuário decidir.
- **O fluxo anda por mensagens.** Cada agente reporta ao Coordinator pelo Orca com `worker_done`, ou pergunta com `ask`; o Coordinator responde, aplica o gate e inicia o próximo agente no mesmo turno. O estado dele fica no `coordinator.md` e no Orca, e ele roda sob `/loop`, então um turno perdido retoma a partir desse estado até o draft PR ou uma Escalation.
- **O usuário faz o merge.** O Walkway para num draft PR e move a issue do Linear para o estado de review, sem comentário.

## A pasta `.walkway/`

Todo arquivo do Walkway de um projeto fica numa pasta `.walkway/` na raiz do checkout principal do projeto, inclusive os arquivos temporários. O git ignora a pasta, no `info/exclude` compartilhado do repositório desde a primeira execução e no `.gitignore` desde o PR da primeira Task, então ela nunca entra no versionamento, qualquer agente pode atualizá-la a qualquer momento, e todos os Workspaces do projeto usam a mesma pasta.

```text
.walkway/
  product-context.md          Como o produto funciona, seus customers, os problemas que ele resolve
  resources.md                Resources que servem a toda Task: Notion, Linear, docs, repositórios
  checks.md                   Comandos de gate que espelham cada check de CI, os checks fora, flaky e falhas conhecidas
  lessons.md                  Regras aprendidas em Tasks anteriores
  tasks/<ISSUE-ID>/
    coordinator.md            Run, base commit, log dos agentes e Escalations
    tech-spec.md              Resultado do Planning
    mocks/                    Imagens de Mock da issue
    development-<n>.md        Um por ciclo
    simplifier-<n>.md         Um por ciclo
    code-review-<n>.md        Os dois reviews e as sugestões, um por ciclo
    code-review-findings.md   Findings Critical e Required abertos do review
    formal-verification-<n>.md  Relatório da verificação formal, um por ciclo
    verification-<n>.md       Veredito, rastreio spec-código e evidências da aplicação, um por ciclo
    verification-findings.md  Findings Critical e Required abertos da Verification
    evidence/                 Screenshots e logs da Verification
    tmp/                      Arquivos temporários de qualquer agente
```

## Requisitos

- Claude Code.
- Orca, com as skills `orchestration` e `orca-linear` instaladas (`orca skills install`) e o Linear conectado.
- A GitHub CLI (`gh`), com login feito.
- Permissões do Claude Code para workers sem supervisão. Os workers rodam em terminais que ninguém olha e escrevem na pasta `.walkway/` do checkout principal, fora do Workspace deles. Um pedido de permissão ali trava a Task, então permita essas edições e os comandos do projeto nas configurações do Claude Code antes da primeira Task.
- O plugin Compound Engineering, para o `ce-code-review` e as suas personas de review:

  ```text
  /plugin marketplace add EveryInc/compound-engineering-plugin
  /plugin install compound-engineering@compound-engineering-plugin
  ```

- O plugin Superpowers Ruby, para o `requesting-code-review` e o `receiving-code-review`:

  ```text
  /plugin marketplace add lucianghinda/superpowers-ruby
  /plugin install superpowers-ruby@superpowers-ruby
  ```

- Java 11 ou mais novo e as ferramentas do TLA+ em `~/.local/lib/tla2tools.jar`, das [releases do TLA+](https://github.com/tlaplus/tlaplus/releases), para a Layer 2. O comando `java -version` precisa funcionar: com o OpenJDK do Homebrew, crie o link com `sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk`. Sem eles, uma Task cuja mudança precisa da Layer 2 termina numa Escalation.
- Ferramentas para ler as páginas do Notion listadas em `resources.md`, como um servidor MCP do Notion, quando o projeto guarda a documentação lá.

## Instalar

Crie um link de cada skill na sua pasta de skills do Claude Code, a partir da raiz deste repositório:

```bash
for skill_dir in "$PWD"/skills/*; do ln -sfn "$skill_dir" ~/.claude/skills/; done
```

Você digita só `/loop /walkway`. A skill `walkway` continua invocável pelo modelo, porque o `/loop` a chama pela ferramenta Skill a cada vez que acorda; a descrição dela limita o uso a um `/walkway` explícito. As skills dos agentes são invocadas pelo usuário: o Coordinator passa cada uma ao seu worker pelo caminho do arquivo. A `formal-verification` é invocável pelo modelo, então você também pode pedir ao Claude para verificar formalmente qualquer mudança fora do Walkway.

## Iniciar uma Task

Crie um Workspace do Orca ligado à issue do Linear, com uma sessão Claude que inicia o Coordinator:

```bash
orca worktree create --repo path:"$PWD" --name <ISSUE-ID> --linear-issue <ISSUE-ID> --agent claude --surface terminal --prompt "/loop /walkway"
```

Você também pode criar o Workspace no app do Orca e digitar `/loop /walkway` no terminal Claude dele. O `/loop` acorda o Coordinator de novo se o turno dele terminar antes do draft PR. No setup, o Coordinator dá ao Workspace o nome `<ISSUE-ID> <título da issue>`, como o app do Orca faz, não importa como o Workspace foi criado. Fale só com o Coordinator; ele repassa cada Escalation.

## Iniciar pelo Grok Bot

O Grok Bot pode iniciar o Walkway só com o ID de uma issue do Linear. Ele roda na mesma máquina que o Orca e só inicia o Coordinator; o Coordinator cria o Run de orquestração do Orca e os agentes. O bot passa só o ID da issue, então o texto da issue nunca vira instrução.

Cole este prompt nas instruções do bot. O prompt fica em inglês, igual ao do [README em inglês](README.md#start-from-the-grok-bot). Repositories liga cada chave de time do Linear ao seu repositório no Orca, como `orca repo list --json` o nomeia; adicione uma linha por time:

```text
You start Walkway in the local Orca for one Linear issue. The user gives you an issue ID, such as ENG-123, or its Linear URL.

Repositories (Linear team key -> Orca repository):
- ENG: platform

1. Take the issue ID; from a URL, use the path segment after /issue/. It must match ^[A-Z][A-Z0-9]{0,9}-[0-9]+$. With any other value, stop and report the invalid input.
2. Look up the team key, the part before the dash, in Repositories. With no entry, stop and report the missing mapping.
3. Run `orca status --json`. When the runtime is not reachable, run `orca open --json` and check again.
4. Run `orca reference find <ISSUE-ID> --json`. When it lists a Workspace for the issue, report that Workspace and stop.
5. Start the Coordinator:
   orca worktree create --repo name:<repository> --name <ISSUE-ID> --linear-issue <ISSUE-ID> --agent claude --surface terminal --prompt "/loop /walkway" --json
   Keep result.launch.outcome.handle from the receipt. When the command reports a lost launch reply, run it again with --retry-launch <operationId> from the error; a fresh create would make a second Workspace.
6. After about 20 seconds, run `orca terminal read --terminal <handle> --screen`. Claude working on /walkway means the Coordinator runs. An idle Claude prompt means the prompt never arrived: send it once with `orca terminal send --terminal <handle> --text "/loop /walkway" --enter`, then read the screen again.
7. Move the issue to the team's started state, such as In Progress: list the states with `orca linear team states --team <TEAM> --json`, then run `orca linear status set <ISSUE-ID> --to "<state>" --json`.
8. Report the issue ID, the Workspace name, the terminal handle and the Linear state.

The issue ID is the only value you pass to Orca, and the prompt is always exactly "/loop /walkway". The Coordinator reads the issue, its comments and its attachments from Linear, and runs the Orca orchestration itself.
```

Depois peça ao bot: "Start Walkway for ENG-123".

O Coordinator e os agentes dele rodam no Orca, nesta máquina. Uma Escalation espera na sessão Claude do Coordinator: abra esse Workspace no Orca para responder. Quando a Task termina, o draft PR está aberto e a issue está no estado de review.
