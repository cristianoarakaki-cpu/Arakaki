"""Verificações de contrato de arquivos e fluxo do importador; não executa Access/VBA."""
from pathlib import Path
import re,xml.etree.ElementTree as ET,datetime as dt,openpyxl
root=Path(__file__).resolve().parents[1]
b=(root/'modImportarFeriasDCE.bas').read_bytes()
try:src=b.decode('utf-8')
except UnicodeDecodeError:src=b.decode('cp1252')
src=src.replace('\r\n','\n')
ps=(root/'FeriasDCE.ps1').read_text(encoding='utf-8-sig')
fields=re.findall(r'"([^"]+)"',src.split('    F_Campos = Array(',1)[1].split(')\n',1)[0])
expected=['Codigo do Servidor','Observação','Periodo Aquisitivo_1','Periodo Aquisitivo_2','Agendar Após','Ferias_30_Inicio','Ferias_30_Final','Ferias_Par_1QIn','Ferias_Par_1QFin','Ferias_Par_2QIn','Ferias_Par_2QFin','Programacao_Ano','Processo_20Dias']
assert fields==expected
assert all("'"+f+"'" in ps for f in fields)
assert len(fields)==13 and 'ID_Ferias' not in fields
assert max(map(len,src.splitlines()))<=1023
assert 'doc.resolveExternals = False' in src and '"ProhibitDTD", True' in src
assert src.index('If MsgBox("O relatorio')<src.index('ws.BeginTrans')<src.index('rs.AddNew')<src.index('ws.CommitTrans')
assert src.count('F_LerBase db, tabela, base, incompletos')==2
assert 'If row("Autorizado") Then' in src
assert not re.search(r'\b(?:UPDATE|DELETE|ALTER|CREATE TABLE|CREATE INDEX)\s+\[',src,re.I)
assert 'Open lockPath For Binary Access Read Write Lock Read Write' in src
assert '.ferias-importacao.lock' in src and 'If transacao Then ws.Rollback' in src
assert 'F_Assinatura(existente) = row("Assinatura")' in src
assert '"DUPLICATA_BASE"' in src and '"DIVERGENTE_ARQUIVO"' in src
import sys
if len(sys.argv)>1:
 path=Path(sys.argv[1]);xml=ET.parse(path/'base-enviada.xml')
 rows=xml.findall('./Registros/Registro');seen=set()
 for row in rows:
  vals={n.attrib['nome']:None if n.attrib.get('nulo')=='1' else n.text or '' for n in row}
  assert list(vals)==fields
  assert int(vals['Codigo do Servidor'])>0
  start=dt.date.fromisoformat(vals['Periodo Aquisitivo_1']);end=dt.date.fromisoformat(vals['Periodo Aquisitivo_2'])
  assert start<=end and dt.date.fromisoformat(vals['Agendar Após'])==end+dt.timedelta(days=2)
  flag=int(vals['Processo_20Dias']);assert flag in [0,-1]
  key=(int(vals['Codigo do Servidor']),start,end,flag)
  assert key not in seen;seen.add(key)
  if vals['Ferias_30_Inicio']:
   assert (dt.date.fromisoformat(vals['Ferias_30_Final'])-dt.date.fromisoformat(vals['Ferias_30_Inicio'])).days==(19 if flag==-1 else 29)
  else:
   assert flag==0
   for a,b in [('Ferias_Par_1QIn','Ferias_Par_1QFin'),('Ferias_Par_2QIn','Ferias_Par_2QFin')]:assert (dt.date.fromisoformat(vals[b])-dt.date.fromisoformat(vals[a])).days==14
 wb=openpyxl.load_workbook(path/'teste.xlsx')
 assert wb.sheetnames==['Colar_Access','Pendencias','Instrucoes']
 assert [c.value for c in wb['Colar_Access'][1]]==fields
 assert wb['Colar_Access'].max_row==3
 assert wb['Colar_Access']['L2'].number_format=='0000'
print('CONTRATO_OK: campos, XML, datas, Excel preservado e verificacoes estaticas do fluxo VBA; VBA nao executado.')
