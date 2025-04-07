""" import spacy
nlp = spacy.load("es_core_news_sm")  # Modelo en español

frase = "quiero un abrazo"
doc = nlp(frase)
formas_bases = [token.lemma_ for token in doc]

print(formas_bases)  # ['querer', 'uno', 'abrazar']
 """

import spacy

# Cargar el modelo en español
nlp = spacy.load("es_core_news_sm")

# Frase de ejemplo
frase = "quiero un abrazando"
doc = nlp(frase)

# Mostrar las palabras y su forma base
for token in doc:
    print(f"{token.text} → {token.lemma_}")
