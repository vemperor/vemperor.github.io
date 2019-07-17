---
layout: post
title:  "Презентеры для моделей Ecto"
date:   2019-04-30
categories: programming
uid: ecto-presenters
---

## Предисловие
Продолжение статьи про [организацию файлов в типичном Phoenix-проекте]({% uid_url alternative-phoenix-contexts-approach %}).

Время идёт, проекты разрастаются, появляются новые подходы. Расскажу про ещё один.

Перед прочтением рекомендую ознакомиться с [предыдущим постом]({% uid_url alternative-phoenix-contexts-approach %}) (но это не обязательно).

## Проблема
На написание "презентера" меня побудила следующая проблема: в нескольких разных модулях потребовались одни и те же данные. Но не хранимые в БД, а вычисляемые на основе них.

В качестве примера возьмём два случая:
1. Какой-нибудь вычисляемый статус. Допустим, все люди, которые больше 1.8 метров высотой, считаются высокими:
```elixir
def height_status(human) do
  if human.height > 180, do: "tall", else: "short"
end
```
2. Переводы. В поставке Phoenix есть библиотека Gettext, поэтому речь примерно про это:
```elixir
def gender_text(human) do
  Gettext.dgettext(App.Gettext, "human", human.gender, [])
end
```

## Куда этот код можно положить
Есть два исходных варианта. И один новый.

### В модель (в понимании Ecto)
```elixir
# lib/app/models/human.ex

defmodule App.Models.Human do
  use Ecto.Schema

  schema "humans" do
    field(:height, :string)
    field(:gender, :string)
  end

  # ...

  def height_status(human) do # ...
  def gender_text(human) do # ...
end
```

Не самый плохой вариант. По крайней мере лучше, чем дублировать эти методы.

Но в результате:
1. Модель становится "толстой"
2. Модель отвечает не только за хранение данных
3. Повышается связность в проекте, потому что функции моделей используются ещё и в слое отображения (прямое следствие предыдущего пункта)

### В контекст
```elixir
# lib/app/contexts/humans.ex

defmodule App.Contexts.Humans do
  def list() do # ...
  def get() do # ...
  def create() do # ...
  def update() do # ...
  def delete() do # ...

  def height_status(human) do # ...
  def gender_text(human) do # ...
end
```

Тоже не самый плохой вариант. Уже лучше, чем в модель.

Но все те же проблемы в результате:
1. Контекст также как и модель становится "толстым"
2. Контекст отвечает не только за операции (изменение/получение) над данными, но и за вывод
3. Повышается связность в проекте, потому что функции контекстов используются ещё и в слое отображения (прямое следствие предыдущего пункта)

### В презентер
Сразу оговорюсь, что, ввиду отсутствия в erlang/elixir ООП "с классами" презентер (или *декоратор*) не использует наследование.
Поэтому всё сильно упрощается:
```elixir
# lib/app/presenters/human.ex

defmodule App.Presenters.Human do
  def height_status(human) do # ...
  def gender_text(human) do # ...
end
```

И у нас появляется модуль, ответственный за вычисление данных для отображения.

По привычке называю его "презентер". И, думаю, это подходящее название.

Модели и контексты не толстеют, буква **S** из [**SOLID**'а](https://ru.wikipedia.org/wiki/SOLID_(%D0%BE%D0%B1%D1%8A%D0%B5%D0%BA%D1%82%D0%BD%D0%BE-%D0%BE%D1%80%D0%B8%D0%B5%D0%BD%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%BD%D0%BE%D0%B5_%D0%BF%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5)) соблюдена.

## Немного про ограничения и антипаттерны
Ввиду того, что модуль этот был сделан исключительно для отображения, использование его для других целей будет нарушением принципа **SOLID** (всё ещё первой буквы).

Поясняю: если презентер по какой-то причине используется в модели или контексте, значит на основе вычисляемых данных будет совершаться получение и/или изменение в БД. Что делает **операции** зависимыми от **отображения**. В результате вместе с SOLID'ом есть высокая вероятность нарушения **принципа наименьшего удивления**.

Куда девать код, который относится и к отображению и к операциям и к хранению? Не знаю. Ещё не придумал. Но когда-нибудь напишу ответ и на этот вопрос.