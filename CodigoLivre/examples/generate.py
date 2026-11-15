"""Cria somente dados fictícios para testar o importador local."""
from pathlib import Path
import sqlite3,zipfile
root=Path(__file__).parent
(root/'servidores.csv').write_text('Id;Nome;Setor;Horas\n1;Pessoa Exemplo A;Enfermagem;12\n2;Pessoa Exemplo B;Administrativo;6\n3;Pessoa Exemplo C;Enfermagem;12\n',encoding='utf-8')
p=root/'servidores.sqlite'
if p.exists():p.unlink()
with sqlite3.connect(p) as db:
 db.execute('PRAGMA journal_mode=DELETE')
 db.execute('CREATE TABLE servidores(id INTEGER PRIMARY KEY, nome TEXT NOT NULL, setor TEXT, horas INTEGER CHECK(horas>=0))')
 db.executemany('INSERT INTO servidores VALUES(?,?,?,?)',[(1,'Pessoa Exemplo A','Enfermagem',12),(2,'Pessoa Exemplo B','Administrativo',6),(3,'Pessoa Exemplo C','Enfermagem',12)])
 (root/'servidores.sql').write_text('\n'.join(db.iterdump()),encoding='utf-8')
parts={
'[Content_Types].xml':'''<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>''',
'_rels/.rels':'''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="r1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''',
'xl/workbook.xml':'''<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Horas" sheetId="1" r:id="r1"/></sheets></workbook>''',
'xl/_rels/workbook.xml.rels':'''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="r1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>''',
'xl/worksheets/sheet1.xml':'''<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData><row r="1"><c r="A1" t="inlineStr"><is><t>Pessoa</t></is></c><c r="B1" t="inlineStr"><is><t>Horas</t></is></c></row><row r="2"><c r="A2" t="inlineStr"><is><t>Pessoa Exemplo A</t></is></c><c r="B2"><v>12</v></c></row><row r="3"><c r="A3" t="inlineStr"><is><t>Pessoa Exemplo B</t></is></c><c r="B3"><v>6</v></c></row><row r="4"><c r="A4" t="inlineStr"><is><t>Total</t></is></c><c r="B4"><f>SUM(B2:B3)</f><v>18</v></c></row></sheetData></worksheet>'''}
with zipfile.ZipFile(root/'horas.xlsx','w',zipfile.ZIP_DEFLATED) as z:
 for name,content in parts.items():z.writestr(name,'<?xml version="1.0" encoding="UTF-8"?>'+content)
(root/'LEIA-ME.txt').write_text('DADOS FICTÍCIOS.\nDescompacte o ZIP de exemplos antes de importar cada arquivo no app.\n\nExcel: aba Horas, linha inicial 1, quantidade 8. Pedido: explique a fórmula de B4 e os limites desta prévia. O valor salvo é 18; o app não recalcula.\nCSV: pedido: identifique os setores e descreva as colunas.\nSQLite: tabela servidores, linha 1, quantidade 8. Pedido: avalie a estrutura e as restrições fornecidas. Existem 3 registros fictícios.\n\nNenhum desses exemplos contém informações pessoais reais.\n',encoding='utf-8')
print('Exemplos gerados em',root)
