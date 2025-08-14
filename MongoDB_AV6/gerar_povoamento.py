import random
import itertools
from datetime import datetime, timedelta
now = datetime.now()

def format_date(date: datetime) -> str:
    date_str = date.strftime("%Y-%m-%dT%H:%M:%SZ")  
    return f"new Date('{date_str}')"

def unencode_date(date_js_code) -> datetime:
    date_code :str = date_js_code.code
    date_code = date_code.lstrip("new Date('").rstrip("')")
    date = datetime.strptime(date_code, "%Y-%m-%dT%H:%M:%SZ")
    return date

nomes = {
    "Brasil": {
        "masculino": ["João", "Pedro", "Lucas", "Carlos", "Rafael", "Gustavo", "André", "Henrique", "Caio", "Matheus"],
        "feminino": ["Maria", "Ana", "Camila", "Beatriz", "Juliana", "Carla", "Fernanda", "Isabela", "Letícia", "Mariana"],
        "sobrenomes": ["Silva", "Santos", "Oliveira", "Pereira", "Costa", "Rodrigues", "Almeida", "Lima", "Araújo", "Fernandes"]
    },
    "Espanha": {
        "masculino": ["José", "Alejandro", "Santiago", "Miguel", "Fernando", "Luis", "Diego", "Manuel", "Álvaro", "Javier"],
        "feminino": ["Lucía", "Sofía", "Valentina", "Martina", "Catalina", "Paula", "Florencia", "Gabriela", "Alejandra", "Daniela"],
        "sobrenomes": ["García", "Martínez", "López", "Hernández", "González", "Torres", "Ramírez", "Flores", "Vargas", "Morales"]
    },
    "Inglaterra": {
        "masculino": ["James", "John", "Michael", "William", "David", "Christopher", "Daniel", "Matthew", "Andrew", "Joseph"],
        "feminino": ["Emily", "Emma", "Olivia", "Sophia", "Ava", "Isabella", "Charlotte", "Amelia", "Mia", "Abigail"],
        "sobrenomes": ["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Taylor", "Anderson", "Thomas"]
    },
    "França": {
        "masculino": ["Louis", "Pierre", "Antoine", "Hugo", "Julien", "Mathieu", "François", "Étienne", "Gabriel", "Olivier"],
        "feminino": ["Camille", "Chloé", "Juliette", "Élise", "Claire", "Sophie", "Amélie", "Madeleine", "Aurélie", "Manon"],
        "sobrenomes": ["Dubois", "Durand", "Moreau", "Lefevre", "Laurent", "Simon", "Michel", "Bernard", "Girard", "Rousseau"]
    },
    "Itália": {
        "masculino": ["Giovanni", "Luca", "Matteo", "Marco", "Antonio", "Alessandro", "Francesco", "Leonardo", "Paolo", "Roberto"],
        "feminino": ["Giulia", "Sofia", "Martina", "Chiara", "Francesca", "Aurora", "Alessia", "Elena", "Bianca", "Gabriella"],
        "sobrenomes": ["Rossi", "Russo", "Ferrari", "Esposito", "Bianchi", "Romano", "Gallo", "Costa", "Fontana", "Conti"]
    },
    "Alemanha": {
        "masculino": ["Hans", "Friedrich", "Wolfgang", "Karl", "Stefan", "Heinrich", "Rolf", "Matthias", "Jürgen", "Andreas"],
        "feminino": ["Anna", "Emma", "Mia", "Hannah", "Leonie", "Amelie", "Sophia", "Laura", "Lena", "Johanna"],
        "sobrenomes": ["Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Wagner", "Becker", "Hoffmann", "Schäfer", "Koch"]
    },
    "Japão": {
        "masculino": ["Hiroshi", "Takashi", "Kenji", "Satoshi", "Takeshi", "Shinji", "Haruto", "Kaito", "Ren", "Daichi"],
        "feminino": ["Yui", "Aoi", "Hina", "Sakura", "Haruka", "Akari", "Rin", "Miyu", "Nanami", "Mei"],
        "sobrenomes": ["Tanaka", "Suzuki", "Takahashi", "Kobayashi", "Yamamoto", "Matsumoto", "Inoue", "Kato", "Fujimoto", "Shimizu"]
    },
    "Árabia Saudita": {
        "masculino": ["Omar", "Hassan", "Ali", "Mohammed", "Ibrahim", "Yusuf", "Tariq", "Mustafa", "Samir", "Khalid"],
        "feminino": ["Aisha", "Fatima", "Layla", "Zahra", "Mariam", "Yasmin", "Nadia", "Amira", "Salma", "Noor"],
        "sobrenomes": ["Al-Farouk", "Haddad", "Abbas", "Nasr", "Rahman", "Kassem", "Darwish", "Saleh", "Saidi", "Bakir"]
    }
}

def gerar_nome(sexo, origem):   
    primeiro_nome = random.choice(nomes[origem][sexo])
    sobrenome = random.choice(nomes[origem]["sobrenomes"])
    sobrenome_2 = ""
    if random.random() < 0.3:
        while 1:
            sobrenome_2 = " " + random.choice(nomes[origem]["sobrenomes"])
            if sobrenome_2 != " " + sobrenome: break
            
    return f"{primeiro_nome} {sobrenome}{sobrenome_2}"

def gerar_email(nome, dominio=False):
    nome_partes = nome.split(" ")
    
    parte1 = random.choice(nome_partes) + random.choice(['.', '']) + random.choice([*nome_partes, str(random.randint(10, 999))])
    parte2 = random.choice(["gmail.com","yahoo.com","outlook.com","hotmail.com", "yahoo.com.br"]) if not dominio else nome.lower().replace(" ", "") + ".com"
    return parte1 + '@' + parte2

def gerar_data(data_base, tempo_minimo, tempo_maximo):
    dias_aleatorios = random.uniform(tempo_minimo, tempo_maximo)
    nova_data = data_base - timedelta(days=dias_aleatorios)
    
    return nova_data

class JSCode:
    def __init__(self, code):
        self.code = code
    def __repr__(self):
        return self.code

def gerar_insertmany_js(nome_collection, documentos):
    def dict_to_js(obj):
        if isinstance(obj, JSCode):
            return obj.code
        elif isinstance(obj, str):
            return f'"{obj}"'
        elif isinstance(obj, dict):
            itens = [f'"{k}": {dict_to_js(v)}' for k, v in obj.items()]
            return "{" + ", ".join(itens) + "}"
        elif isinstance(obj, list):
            return "[" + ", ".join(dict_to_js(v) for v in obj) + "]"
        else:
            return str(obj)

    conteudo_js = f"db.{nome_collection}.insertMany({dict_to_js(documentos)});\n".replace(" None", " null")
    return conteudo_js

def gerar_peso_altura():
    bmi = random.uniform(20, 28)
    altura = random.uniform(160, 200)
    peso = bmi * (altura/100)**2
    
    return round(altura, 2), round(peso, 2)

pessoas, jogadores, treinadores, funcionarios, socios = [], [], [], [], []

# Gerar pessoas
for i in range(300):
    tipo = random.choices(['Jogador', 'Treinador', 'Funcionário', 'Sócio'], [0.2, 0.05, 0.2, 0.595], k=1)[0]
    partida_id = "".join([str(random.randint(0, 9)) for i in range(11)])
    telefones = ["".join([str(random.randint(0, 9)) for i in range(13)]) for _ in range(random.randint(1, 3))]
    sexo = random.choice(['masculino', 'feminino']) if tipo != 'Jogador' else 'masculino'
    nacionalidade = random.choices(tuple(nomes.keys()), (30, 1, 1, 1, 1, 1, 1, 1), k=1)[0]
    nome = gerar_nome(sexo, nacionalidade)
    emails = [gerar_email(nome) for _ in range(random.randint(0, 3))]
    data_nascimento = gerar_data(now, 16*365.25, 35*365.25) if tipo == 'Jogador' else gerar_data(now, 18*365.25, 70*365.25)
    
    pessoas.append({'_id':partida_id, 'nome':nome, 'nacionalidade':nacionalidade, 'sexo':sexo, 'emails':emails, 'telefones':telefones, 'data_nascimento':JSCode(format_date(data_nascimento))})
    
    if tipo == 'Jogador':
        altura, peso = gerar_peso_altura()
        jogadores.append({'_id':partida_id, 'contratos':[], 'lesoes':[], 'punicoes':[], 'altura':altura, 'peso':peso})
    elif tipo == 'Treinador':
        treinadores.append({'_id':partida_id, 'contratos':[]})    
    elif tipo == 'Funcionário':
        funcao = random.choice(('Zelador', 'Gerente de Marketing', 'Cozinheiro', 'Gerente Admnistrativo', 'Motorista', 'Segurança'))
        contratacao = gerar_data(data_nascimento, -18*365.25, -(now.year-data_nascimento.year)*365.25)
        salario = round(random.uniform(1600, 5000), 2) if funcao != 'Gerente Admnistrativo' else round(random.uniform(8000, 10000), 2)
        demitido = random.random() < 0.2
        contrato_fim = None if not demitido else gerar_data(contratacao, -30, -(now.year-contratacao.year)*365.25) 
        razao_fim = None if not demitido else random.choice(("Demissão", "Aposentadoria", "Morte"))
        funcionarios.append({'_id':partida_id, 'gerente':None, 'funcao':funcao, 'salario':salario, 'contrado_em':JSCode(format_date(contratacao)), 'fim_contrato':JSCode(format_date(contrato_fim)) if contrato_fim else None, 'razao_fim':razao_fim})            
    elif tipo == 'Sócio':
        socio_desde = gerar_data(data_nascimento, -18*365.25, -(now.year-data_nascimento.year)*365.25)
        socios.append({'_id':partida_id, 'socio_desde':JSCode(format_date(socio_desde)), 'pagamento_mensal': random.choice((19.99, 59.99, 199.99))})

gerentes = [func['_id'] for func in funcionarios if func['funcao'] == "Gerente Admnistrativo"]
for func in funcionarios:
    if func['funcao'] != "Gerente Admnistrativo":
        func['gerente'] = random.choice(gerentes)
            
# Gerar clubes adversários
times = {
    "Brasil": {
        "partes": [
            "Atlético", "Clube", "Esporte", "União", "Futebol", "Sport", "Grêmio", "Nacional", "Vasco", "Bahia",
            "Fortaleza", "Cruzeiro", "Corinthians", "Flamengo", "Palmeiras", "Internacional", "Botafogo", "Santos"
        ],
        "animais": [
            "Leões", "Águias", "Tigres", "Gaviões", "Furacões", "Lobos", "Panteras", "Jacarés", "Cachorros", "Cavalos"
        ],
        "cores": [
            "Vermelho", "Azul", "Verde", "Preto", "Branco", "Amarelo"
        ]
    },
    "Inglaterra": {
        "partes": [
            "United", "City", "Rovers", "Athletic", "Wanderers", "Rangers", "Town", "County", "FC", "Albion",
            "Hotspurs", "Hearts", "Thistle", "Valley", "Dons", "Borough", "Olympic"
        ],
        "animais": [
            "Lions", "Eagles", "Tigers", "Hawks", "Wolves", "Panthers", "Bears", "Foxes", "Sharks", "Bulls"
        ],
        "cores": [
            "Red", "Blue", "Green", "Black", "White", "Yellow"
        ]
    },
    "Espanha": {
        "partes": [
            "Club", "Atlético", "Deportivo", "Real", "Unión", "Sport", "Ciudad", "Nacional", "Fútbol", "Independiente"
        ],
        "animais": [
            "Leones", "Águilas", "Tigres", "Halcones", "Lobos", "Panteras", "Osos", "Zorros", "Tiburones", "Toros"
        ],
        "cores": [
            "Rojo", "Azul", "Verde", "Negro", "Blanco", "Amarillo"
        ]
    },
    "França": {
        "partes": [
            "Olympique", "Club", "Sporting", "Union", "Racing", "Stade", "Athletic", "Football", "Ville", "Equipe"
        ],
        "animais": [
            "Lions", "Aigles", "Tigres", "Faucons", "Loups", "Panthères", "Ours", "Renards", "Requins", "Taureaux"
        ],
        "cores": [
            "Rouge", "Bleu", "Vert", "Noir", "Blanc", "Jaune"
        ]
    },
    "Itália": {
        "partes": [
            "Associazione", "Calcio", "Club", "Unione", "Sportiva", "Nazionale", "Atletico", "Virtus", "Città", "Real"
        ],
        "animais": [
            "Leoni", "Aquile", "Tigri", "Falchi", "Lupi", "Pantere", "Orsi", "Volpi", "Squali", "Tori"
        ],
        "cores": [
            "Rosso", "Blu", "Verde", "Nero", "Bianco", "Giallo"
        ]
    },
    "Alemanha": {
        "partes": [
            "Verein", "Sport", "FC", "SC", "TSV", "Eintracht", "Borussia", "Union", "Dynamo", "SV"
        ],
        "animais": [
            "Löwen", "Adler", "Tiger", "Falken", "Wölfe", "Panther", "Bären", "Füchse", "Haie", "Stiere"
        ],
        "cores": [
            "Rot", "Blau", "Grün", "Schwarz", "Weiß", "Gelb"
        ]
    },
    "Japão": {
        "partes": [
            "Sakkā", "Kurabu", "Supōtsu", "Yunaiteddo", "Asurechikku", "FC", "SC", "Intānashonaru", "Tōkyō", "Ōsaka"
        ],
        "animais": [
            "Raionzu", "Īgurusu", "Taigāsu", "Hōkusu", "Urubuzu", "Pansāzu", "Bēāzu", "Fokkusu", "Shākusu", "Buruzu"
        ],
        "cores": [
            "Reddo", "Burū", "Gurīn", "Burakku", "Howaito", "Ierō"
        ]
    },
    "Árabia Saudita": {
        "partes": [
            "Nadi", "Al-Ittihad", "Ar-Riyadah", "Al-Fariq", "An-Nadi", "Al-Kurah", "Al-Wahda", "Ash-Shabab", "Al-Quwwah", "As-Salam"
        ],
        "animais": [
            "Al-Asad", "An-Nusur", "An-Numur", "As-Suqur", "Adh-Dhiʼab", "Al-Fuhud", "Ad-Dibbah", "Ath-Thi‘lab", "Asmak Al-Qirsh", "At-Tiyur"
        ],
        "cores": [
            "Al-Ahmar", "Al-Azraq", "Al-Akhdar", "Al-Aswad", "Al-Abyad", "Al-Asfar"
        ]
    }
}

def gerar_nome_time(origem):
    if origem not in times:
        raise ValueError(f"Origem '{origem}' não suportada. Opções: {', '.join(times.keys())}")

    dicionario = times[origem]

    partes = dicionario.get("partes", [])
    animais = dicionario.get("animais", [])
    cores = dicionario.get("cores", [])

    escolha = random.choice(["animal", "cor"])

    if escolha == "animal" and animais:
        palavra1 = random.choice(partes) if partes else ""
        palavra2 = random.choice(animais)
    elif cores:
        palavra1 = random.choice(partes) if partes else ""
        palavra2 = random.choice(cores)
    else:
        palavra1 = random.choice(partes) if partes else "Time"
        palavra2 = random.choice(partes) if partes else "FC"

    return f"{palavra1} {palavra2}"

clubes_adversarios = []

for i in range(20):
    nacionalidade = random.choices(tuple(nomes.keys()), (7, 1, 1, 1, 1, 1, 1, 1), k=1)[0]
    nome = gerar_nome_time(nacionalidade)
    clube_id = "".join([str(ord(char)) for char in f'{nome}{random.randint(4000, 9000)}'])
    sigla = f"{nome[0]}{nome.split(" ")[1][0]}"
    
    clubes_adversarios.append({'_id':clube_id, 'nome':nome, 'sigla':sigla.upper(), 'pais':nacionalidade})

# Gerar contratos
def estrutura_contrato(pessoa, tipo, salario_mod, idade_min, clube=None):
    inicio = gerar_data(unencode_date(pessoa['data_nascimento']), -idade_min*365.25, -(now.year - unencode_date(pessoa['data_nascimento']).year) * 365.25)
    pagamento_mensal = abs(random.uniform(1, 4) * (1052368 * (now.year - inicio.year) + 5000) * salario_mod)
    fim = gerar_data(inicio, -365.25, -10*365.25)
    status = "Ativo" if now.year - fim.year <= 0 else "Encerrado"
    return {"clube":clube, "tipo":tipo, "data_inicio":JSCode(format_date(inicio)), "pagamento_mensal":round(pagamento_mensal, 2), "status":status, "data_fim":JSCode(format_date(fim))}


for i in range(len(jogadores)):
    pessoa = [p for p in pessoas if p['_id'] == jogadores[i]['_id']][0]
    nosso_contrato = estrutura_contrato(pessoa, 'Jogador', 1, 16)
    jogadores[i]['contratos'].append(nosso_contrato)
    
    # Gerar contratos de outros times que nossos jogadores tiveram    
    for j in range(random.randint(0, 2)): 
        jogadores[i]['contratos'].append(estrutura_contrato(pessoa, 'Jogador', 0.9,  16, random.sample(clubes_adversarios, k=1)[0]['_id']))

for i in range(len(treinadores)):
    pessoa = [p for p in pessoas if p['_id'] == jogadores[i]['_id']][0]
    nosso_contrato = estrutura_contrato(pessoa, 'Treinador', 0.2, 18)
    treinadores[i]['contratos'].append(nosso_contrato)
    
    for j in range(random.randint(0, 2)): 
        treinadores[i]['contratos'].append(estrutura_contrato(pessoa, 'Treinador', 0.16,  16, random.sample(clubes_adversarios, k=1)[0]['_id']))
    
# Gerar campeonatos
campeonatos = []

for nome in itertools.product(["Copa", "Taça", "Mundial", "Campeonato"], ["do Brasil", "das Américas", "do Mundo", "do Universo", "de Xique-Xique"]):
    nome = " ".join(nome)
    pais = "Brasil" if "do Brasil" in nome or "das Américas" in nome else random.choice(tuple(nomes.keys()))
    data_inicio = JSCode(format_date(gerar_data(now, 365.25, 10*365.25)))
    duracao = random.choice((30, 60, 90, 180, 300))
    data_fim = JSCode(format_date(gerar_data(unencode_date(data_inicio), -duracao, -duracao)))
    resultado = random.choice(("Campeão", "Finalista", "Eliminado"))
    premio = round(random.uniform(1, 50) * (10**6 if resultado == "Campeão" else 10**5 if resultado == "Finalista" else 0), 2)

    # Gerar partidas
    partidas = []
    for time in random.sample(clubes_adversarios, k=7):
        partida_id = "".join([str(ord(c)) for c in nome+time['nome']])
        id_adversario = time['_id']
        treinador = random.sample(treinadores, k=1)[0]['_id']
        jogaram = [j['_id'] for j in random.sample(jogadores, k=len(jogadores)) if 
                    unencode_date(data_inicio).year - unencode_date([p for p in pessoas if p['_id'] == j['_id']][0]['data_nascimento']).year 
                    >= 16][:11]
        reserva = [j['_id'] for j in random.sample(jogadores, k=len(jogadores)) if 
                    unencode_date(data_inicio).year - unencode_date([p for p in pessoas if p['_id'] == j['_id']][0]['data_nascimento']).year 
                    >= 16 and j['_id'] not in jogaram][:5]
        data = JSCode(format_date(gerar_data(unencode_date(data_inicio), -1, -duracao)))
        duracao = random.randint(90, 120)
        gols_equipe, gols_adversario = random.choices(tuple(range(0, 11)), tuple(range(11, 0, -1)), k=2)
        resultado_partida = 'Vitória' if gols_equipe > gols_adversario else 'Empate' if gols_equipe == gols_adversario else 'Derrota'
        espectadores = random.randint(1000, 50000)
        receita = round(espectadores*random.uniform(20, 200), 2)
        partidas.append({'_id':partida_id, 'adversario': id_adversario, 'treinador':treinador, 'jogadores':jogaram, 'reserva':reserva, 'data':data, 'duracao':duracao, 'gols_equipe':gols_equipe, 'gols_adversario':gols_adversario, 'resultado':resultado_partida, 'espectadores':espectadores, 'receita':receita})
        
        # Gerar lesões
        for i in range(random.randint(0, 2)):
            jogador_lesionado = random.sample(jogaram, k=1)[0]
            gravidade = random.choice(['Leve', 'Moderada', 'Grave'])
            recuperacao = 7 if gravidade == 'Leve' else 30 if gravidade == 'Moderada' else 180
            data_retorno = gerar_data(unencode_date(data), -recuperacao, -recuperacao)
            
            for j in jogadores:
                if j['_id'] == jogador_lesionado:
                    j['lesoes'].append({'id_partida': partida_id, 'gravidade':gravidade, 'data_lesionamento':data, 'data_retorno':JSCode(format_date(data_retorno))})
        
        # Gerar punições
        for i in range(random.randint(0, 2)):
            jogador_punido = random.sample(jogaram, k=1)[0]
            tipo = random.choice(("Cartão Amarelo", "Cartão Vermelho"))
            jogos_suspenso = random.randint(1, 4) if tipo == "Cartão Vermelho" else 0
            
            for j in jogadores:
                if j['_id'] == jogador_punido:
                    j['punicoes'].append({'id_partida': partida_id, 'tipo':tipo, 'data':data, 'jogos_suspenso':jogos_suspenso})
            
        
    campeonatos.append({'nome': nome, 'pais':pais, 'data_inicio':data_inicio, 'data_fim':data_fim, 'resultado':resultado, 'premio':premio, 'partidas':partidas})

# Gerar patrocínios
patrocinios = []

for nome in ("TechPlay Bet", "Viva Bet", "Casa Verde Bet", "GloboWave Bet", "Lunar Bet", "Solaris Bet", "Nexus Financeira", "Atlas Seguros", "Prime Sportswear", "Oceanic Transportes", "Zenith Tecnologia", "Alvorada Imóveis", "Titan Saúde", "Aurora Digital"):
    cnpj = "".join([str(random.randint(0, 9)) for i in range(14)])
    contato = gerar_email(nome, True)
    inicio = gerar_data(now, 30, 5*365.25)
    pagamento_mensal = round(random.uniform(10**6, 20*10**6), 2)
    fim = None if random.random() < 0.8 else JSCode(format_date(gerar_data(inicio, -2*365.25, -(now.year-inicio.year)*365.25)))
    
    patrocinios.append({'_id': cnpj, 'nome':nome, 'contato': contato, 'data_inicio':JSCode(format_date(inicio)), 'pagamento_mensal':pagamento_mensal, 'fim':fim})

# Escrever arquivo
result = """use("gerenciamento_times_esportivos");
db.dropDatabase();
use("gerenciamento_times_esportivos");

db.createCollection("Pessoas");
db.createCollection("Jogadores");
db.createCollection("Treinadores");
db.createCollection("Funcionarios");
db.createCollection("Socios");
db.createCollection("ClubesAdversarios");
db.createCollection("Campeonatos");
db.createCollection("Patrocinios");
"""

result += gerar_insertmany_js('Pessoas', pessoas)
result += gerar_insertmany_js('Jogadores', jogadores)
result += gerar_insertmany_js('Treinadores', treinadores)
result += gerar_insertmany_js('Funcionarios', funcionarios)
result += gerar_insertmany_js('Socios', socios)
result += gerar_insertmany_js('ClubesAdversarios', clubes_adversarios)
result += gerar_insertmany_js('Campeonatos', campeonatos)
result += gerar_insertmany_js('Patrocinios', patrocinios)

with open("MongoDB_AV6/povoamento.js", 'w', encoding='utf-8') as file:
    file.writelines(result)


