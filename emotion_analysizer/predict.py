#-*- coding:utf-8 -*-

import konlpy
import json
import os
import nltk
import numpy as np
import progress as pg
import pickle


from konlpy.tag import Kkma
from konlpy.tag import Okt
from konlpy.utils import pprint

from tensorflow.keras import models
from tensorflow.keras import layers
from tensorflow.keras import optimizers
from tensorflow.keras import losses
from tensorflow.keras import metrics

okt = Okt()

##function definitions
def read_data(filename):
  with open(filename, 'r') as f:
    data = [line.split('\t') for line in f.read().splitlines()]
    data = data[1:]
  return data

def tokenize(doc):
  return ['/'.join(t) for t in okt.pos(doc, norm = True, stem = True)]

def term_frequency(doc):
  return [doc.count(word) for word in selected_words]

def predict_pos_neg1(review):
    token = tokenize(review)
    tf = term_frequency(token)
    data = np.expand_dims(np.asarray(tf).astype('float32'), axis=0)
    score = float(model.predict(data))
    if(score > 0.5):
        print("[{}]는 {:.2f}% 확률로 긍정.^^\n".format(review, score * 100))
    else:
        print("[{}]는 {:.2f}% 확률로 부정.^^;\n".format(review, (1 - score) * 100))

def predict_pos_neg(review):
    token = tokenize(review)
    tf = term_frequency(token)
    data = np.expand_dims(np.asarray(tf).astype('float32'), axis=0)
    score = float(model.predict(data))
    if(score > 0.5):
      return 1
    else:
      return -1
## storing tokenized data in json file
train_data = read_data('ratings_train.txt')
test_data = read_data('ratings_test.txt')
if os.path.isfile("train_docs.json") :
  with open("train_docs.json") as f :
    train_docs = json.load(f)
  with open("test_docs.json") as f :
    test_docs = json.load(f)
else :
  train_docs = [ (tokenize(row[1]), row[2]) for row in train_data ]
  test_docs = [(tokenize(row[1]), row[2]) for row in test_data ]
  with open('train_docs.json', 'w', encoding="utf-8") as make_file :
    json.dump(train_docs, make_file, ensure_ascii=False, indent="\t")
  with open('test_docs.json', 'w', encoding="utf-8") as make_file :
    json.dump(test_docs, make_file, ensure_ascii=False, indent="\t")
tokens = [t for d in train_docs for t in d[0]]
text = nltk.Text(tokens, name='NMSC')
## storing finished


## data pre-processing



if os.path.isfile("selected_words.bin") :
  with open("selected_words.bin", "rb") as f:
    selected_words = pickle.load(f)
  with open("x_train.bin", "rb") as f:
    x_train = pickle.load(f)
  with open("y_train.bin", "rb") as f:
    y_train = pickle.load(f)
  with open("x_test.bin", "rb") as f:
    x_test = pickle.load(f)
  with open("y_test.bin", "rb") as f:
    y_test = pickle.load(f)

else :
  selected_words = [ f[0] for f in text.vocab().most_common(10000) ]
  train_x = [term_frequency(d) for d, _ in train_docs]
  test_x = [term_frequency(d) for d, _ in test_docs]
  train_y = [c for _, c in train_docs]
  test_y = [c for _, c in test_docs]

  x_train = np.asarray(train_x).astype('float32')
  x_test = np.asarray(test_x).astype('float32')
  y_train = np.asarray(train_y).astype('float32')
  y_test = np.asarray(test_y).astype('float32')
  ## data pre-processing ends here
  with open("selected_words.bin", "wb") as f :
    pickle.dump(selected_words, f, protocol = 4)

  with open("x_train.bin", "wb") as f :
    pickle.dump(x_train, f, protocol = 4)

  with open("y_train.bin", "wb") as f :
    pickle.dump(y_train, f, protocol = 4)

  with open("x_test.bin", "wb") as f :
    pickle.dump(x_test, f, protocol = 4)

  with open("y_test.bin", "wb") as f :
    pickle.dump(y_test, f, protocol = 4)

## tensorflow learning
model = models.Sequential()
model.add(layers.Dense(64, activation='relu', input_shape=(10000,)))
model.add(layers.Dense(64, activation='relu'))
model.add(layers.Dense(1, activation='sigmoid'))

model.compile(optimizer=optimizers.RMSprop(lr=0.001),
             loss=losses.binary_crossentropy,
             metrics=[metrics.binary_accuracy])

model.fit(x_train, y_train, epochs=10, batch_size=512)
results = model.evaluate(x_test, y_test)
## tensorflow learning ends here


print("gimdaewon@810 : predict module loaded")

