### Решение тестового задания.

В качестве базы использовал MySQL.
Подключение к базе осуществялется через Perl модуль DBD::mysql.

parse.pl - скрипт, разбирающий лог и записывающий информацию в базу.
Обязательным аргументом к скрипту должен быть путь до файла с логом.
Скрипт использует файл auth.info для получения данных, необходимых
для подключения к базе. В файле auth.info данные указываются в формате
<ключ>=<значение>, без пробелов. Каждая пара ключ значение должна располагаться
на новой строке. В файле должны быть указаны:

db_name=<имя базы данных>
db_address=<IP адрес БД>
user=<имя пользователя для подключения к БД>
pass=<пароль пользователя для подключения к БД>

get_info.cgi - скрипт, вызываемый из html страницы. Так же обращается к файлу
auth.info. Для взаимодействия с веб сервером используется Perl модуль CGI.

index.html - веб страница с формой поиска.

Работа get_info.cgi и отображения index.html в браузере подразумевает наличие настроенного веб сервера.


### Комментарии к заданию:

Есть вероятность, что я не совсем правильно понял формулировку тестового задания.
Не совсем понятно, как можно делать выборку по адресам получателей из двух таблиц,
если адреса получателей хранятся только в таблице log, а в таблице messages есть
только адреса отправителей. Решение создал исходя из своего понимания постановки задачи. 

Вне зависимости от успешности выполнения задания буду рад получить обратную связь.
