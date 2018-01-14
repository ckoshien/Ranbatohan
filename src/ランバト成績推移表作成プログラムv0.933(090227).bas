#include "hspext.as"
#include "hspda.as"
#include "obj.as"

#define	ver			"0.933"
#define	build		"(build20090227)"
#define	ranbatokun	"<a href=\"http:\/\/www.yurica.net\/dam\/\">らんばと君 v2.04<\/a>(2009/02/28現在)<br>"
#define	ranbatohan	"<a href=\"http:\/\/ckoshien.hp.infoseek.co.jp\/contents\/ranbat.html\">らんばとはん v"+ver+"<\/a><br>"
#define	DAM			"<a href=\"http:\/\/www.clubdam.com\/app\/damStation\/clubdamRanking.do?requestNo="
#define	DAMk		"<a href=\"http:\/\/www.yurica.net\/dam\/clubdam_ranking.pl?request_no="



#module
	;標準命令のnotegetは、毎回バッファの先頭から改行を検索していくため、後ろの方の行を取得するのに時間がかかる。
	;そこで、毎回バッファの先頭から辿るのではなく、前回取得した行から辿って行くことで高速化する。
	;
	;また、標準マクロのnotemaxは、毎回バッファの先頭から改行を検索して行数を数えている。
	;そこで、notesel_fastの実行時に1度だけnotemaxを実行することで高速化する。

	#deffunc notesel_fast var prm
		notesel prm
		notemax_fast@ = notemax
		dup buf,prm
		current_line = 0
		current_pos = 0
	return

	#deffunc noteget_fast var dst, int index
		if index < current_line {
			current_line = 0
			current_pos = 0
		}
		repeat index - current_line
			tmp = instr(buf, current_pos, "\n")
			if tmp == -1 {
				dst = ""
				return
			} else {
				current_line = current_line + 1
				current_pos = current_pos + tmp + 2
			}
		loop
		getstr dst,buf,current_pos
	return
#global

;変数定義
	ddim border,5
	rn=""
	sdim filename,2000,6
	pre=""
	se=""
	sdim borderm,24,5
	wait_time=1,5,10,50,100,250,500
	max_id=5
	ser_mode=0;0=拡張IDなし,1=拡張IDあり
;表示設定
	screen 0,640,480
	redraw 0
	color 200,200,255
	boxf 0,0,640,480
	pos 10,13
	color 0,0,0
	font "",12
	titl="ランバト成績月別集計プログラム「らんばとはん」v"+ver+build
	title titl
	mes "らんばとはん設定ファイル"
	pos 150,10
	input filename(0),300,20,0;オブジェクトid=0
	objsize 24,24
	pos 460,9
	button goto "...",*open_ini;オブジェクトid=1
	objsize 90,24
	pos 490,9
	button goto "入力データ設定",*ini_edit;オブジェクトid=2

	pos 10,40
	mes "複月出力ファイル"
	pos 150,40
	input filename(1),300,20,0;オブジェクトid=3
	objsize 24,24
	pos 460,39
	button goto "...",*file_save;オブジェクトid=4
	objsize 110,24
	pos 490,39
	combox ki,20,"HTML形式(複月)\nHTML形式(単月)\nテキスト形式\nHTML形式(複→単)\n";オブジェクトid=5

	pos 10,73 :mes "検索するランバトネーム"
	objsize 15,15
	for i,0,5,1
		pos 35,92+30*i:chkbox "",sr(i);id=6-10
	next
	objprm 6,1	;一番上のチェックボックス強制ＯＮ
	;ランバトネーム入力ボックス
	for i,0,5,1
		pos 60,90+30*i:input rn(i),100,20;id=11-16
	next
	;地域入力ボックス
	objsize 80,40
	for i,0,5,1
		pos 170,90+30*i:input pre(i),60,20;id=16-20
	next
	;性別入力ボックス
	for i,0,5,1
		pos 240,90+30*i:input se(i),60,20;id=21-25
	next

;閾値表示
	color 255,48,48:boxf 320,90,370,110
	color 255,96,96:boxf 320,110,370,130
	color 255,128,128:boxf 320,130,370,150
	color 255,176,176:boxf 320,150,370,170
	color 255,208,208:boxf 320,170,370,190
	color 255,255,255:boxf 320,190,370,210
	for i,0,5,1
		border(i)=99.000-2*i;初期値
	next
	for i,0,5,1
		pos 327,99+21*i:input border(i),38,20;id=26-30
	next
	objsize 110,24
	pos 460,120
	combox sor,20,"最高点順\nリクエストNo.順\nアーティスト名順\n平均点順";オブジェクトid=31
	objsize 60,60
	pos 460,160
	button goto "処理開始",*start;id=32

	color 0,0,0
	pos 10,235 :mes "オプション"
	pos 35,255 :mes "拡張IDファイル"
	pos 120,250 :input filename(5),300,20,0;id=33
	pos 430,250:objsize 24,24:button goto "...",*load_optionID;オブジェクトid=34
	pos 35,280 :objsize 155,15:chkbox "曲ごとの平均点を出力しない",sr(7);id=35
	pos 35,300 :objsize 155,15:chkbox "未検出曲を出力しない",sr(9);id=36
	pos 35,325 :mes "出力HTMLの幅"
	pos 120,320 :objsize 60,24:combox sr(8),20,"1000px\n 900px\n 800px\n 700px\n";id=37
	pos 200,325 :mes "ウェイト"
	pos 245,320 :objsize 60,24:combox sr(10),20,"  1ms\n  5ms\n 10ms\n 50ms\n100ms\n250ms\n500ms\n";id=38
	pos 35,350 :mes "表の上に表示するテキスト"
	pos 35,370 :mesbox filename(3),240,100,5,2000;id=39
	pos 300,350 :mes "表の下に表示するテキスト"
	pos 300,370 :mesbox filename(4),240,100,5,2000;id=40
	pos 370,75 :mes "リクエストNo.のリンク先"
	pos 490,70 :objsize 110,24:combox lin,20,"DAM公式サイト\nかざやさんサイト";オブジェクトid=41
	pos 320,325 :mes "集計曲数上限"
	pos 400,320 :objsize 60,24:combox sr(11),20,"1000曲\n1500曲\n2000曲\n2500曲\n3000曲\n";id=42
	pos 530,160:objsize 60,24
	button goto "停止",*stop_routine;id=43
	redraw 1
;======================================================
;入力データファイル設定ウインドウ(初期状態:非表示)
	screen 1,320,120,2
	color 200,200,255
	boxf 0,0,640,480
	pos 10,13
	color 0,0,0
	font "",12
	title "入力データファイル設定ウイザード"
	pos 10,40:input year(0),40,20;id=0(1)
	pos 55,45:mes "年"
	pos 70,40:input month(0),20,20;id=1(1)
	pos 95,45:mes "月から"+gettime(0)+"年"+gettime(1)+"月まで集計する"
	pos 80,90
	button  goto "設定開始",*in_init;id=2(1)
	pos 160,90
	button  goto "閉じる",*init_end;id=3(1)
;===========================================================
;未検出曲の入力方法選択ウィンドウ(初期状態:非表示)
	screen 2,320,120,2
	color 200,200,255: boxf 0,0,320,120
	pos 10,13: color 0,0,0: font "",12
	title "ランク外曲の点数入力"
	pos 40,90: button goto "入力しない",*no_input;id=0(2)
	pos 120,90: button goto "手入力",*hand_input;id=1(2)
	pos 200,90: button goto "ファイル入力",*file_input;id=2(2)
	pos 40,58:objsize 220,15:chkbox "入力内容を該当データファイルに追記する",add2dat;id=3(2)
;===========================================================
;手入力ウィンドウ(初期状態:非表示)
	screen 3,320,150,2
	color 200,200,255: boxf 0,0,320,150
	pos 10,13: color 0,0,0: font "",12
	title "未検出曲手入力ウインドウ"
	color 0,0,0
	con=""
	pos 10,70:input con,38,20,6;id=0(3)
	objsize 90,20
	pos 40,120:button goto "歌っていない",*no_sing;id=1(3)
	pos 160,120:button goto "ﾗﾝｸ外",*rank_out;id=2(3)
;===========================================================
	gsel 0,1
;デフォルト設定ロード
	exist "default.ini"
	if strsize>0 {
		filename(0)="default.ini"
		alloc buf,strsize
		notesel buf
		noteload "default.ini"
		gosub *load_ini
	}
	onexit goto *end_routine
	stop
;=============================================================
*file_save
	if (ki==0)|(ki==1)|(ki==3):kin="html"
	if ki==2:kin="txt" 
	dialog kin,17,"保存先の選択"
	if stat=1 : filename(1)=refstr
	if stat!=1 : stop
	goto *kousin
;=============================================================
*open_ini
	if (strlen(filename(0))>3)&(max_id==5):gosub *init_save 
	dialog "ini",16,"設定ファイルを開く"
	if stat=1 : filename(0)=refstr
	if stat!=1 : stop
	exist refstr
	alloc buf,strsize
	notesel buf
	if stat=1 : noteload refstr:goto *load_ini
	if stat!=1 : stop
;============================================================
*load_optionID
	dialog "*",16,"拡張IDファイルを開く"
	if stat=1 : filename(5)=refstr
	if stat!=1 : stop
	exist refstr
	alloc buf,strsize
	notesel buf
	if stat=1 : noteload refstr:objprm 33,filename(5)
	if stat!=1 : stop
	dim max_id
	max_id=(notemax+1)/3
	sdim rn,100,max_id
	sdim pre,100,max_id
	sdim se,100,max_id
	ser_mode=1
	for i,0,max_id,1
		noteget rn(i),3*i
		noteget pre(i),1+3*i
		noteget se(i),2+3*i
	next
	dim max_id2
	if max_id > 5 : max_id2 = 5
	for i,0,max_id2,1
		objprm i+11,rn(i)
	next
	for i,0,max_id2,1
		objprm i+16,pre(i)
	next
	for i,0,max_id2,1
		objprm i+21,se(i)
	next
	stop
;============================================================
*load_ini
	max_id2=5
;設定ファイルチェック
	if notemax<22:dialog "これは設定ファイルではありません。\n(データファイルが指定されていません)":stop
	m=(notemax-22)/2+1
	for i,0,m,1
		noteget con,21+2*i;年-月
		if strmid(con,4,1)!="-":dialog "これは設定ファイルではありません。\n("+(22+2*i)+"行が異常です)":stop
	next
;検索ID取得(1-5)
	for i,1,6,1
		noteget rn(i-1),i
	next
;検索都道府県取得(6-10)
	for i,6,11,1
		noteget pre(i-6),i
	next
;検索性別取得(11-15)
	for i,11,16,1
		noteget se(i-11),i
	next
;得点配色閾値取得(16-20)
	for i,16,21,1
		noteget borderm(i-16),i
	next
	for i,3,8,1
		border(i-3)=double(borderm(i-3))
	next
;入力データファイル名取得
	m=(notemax-22)/2+1
	sdim datafile,100,m
	sdim date,10,m
	for i,0,m,1
		noteget date(i),21+2*i;年-月の取得
		noteget datafile(i),22+2*i;datファイル名の取得
	next
	for i,0,m,1
		year(i)=int(strmid(date(i),0,4))
		month(i)=int(strmid(date(i),5,2))
	next
	goto *kousin
;=================================================
*ini_edit
	gsel 1,1
	if (year(0)==0)|(month(0)==0):year(0)=2004:month(0)=1
	objprm 0,year(0)
	objprm 1,month(0)
	stop
*in_init
	mo=(gettime(0)-year(0))*12+gettime(1)-month(0)+1
	i=0:cha=year(0):chb=month(0)
	for chc,0,mo,1
		dialog ""+cha+"年"+chb+"月の入力データはありますか？",2,"入力データ確認"
		if stat==6 {
			dialog "dat;*.htm;*.html",16,""+cha+"年"+chb+"月のらんばと君データ"
			if stat==1 {
				datafile(i)=refstr
				if (cha!=0)&(chb!=0) {
					year(i)=cha
					month(i)=chb
					i=i+1
				}
			}
		}
		chb=chb+1
		if chb==13:cha=cha+1:chb=1
	next
	m=i
	pos 160,70:mes "集計データは"+m+"個"
	stop
*init_end
	gsel 1,-1
	if (strlen(filename(0))>3)&(max_id==5):gosub *init_save 
	stop
;=================================================
*kousin
	gsel 0,1
	objprm 0,filename(0)
	objprm 3,filename(1)
	for i,0,max_id2,1
		objprm i+11,rn(i)
	next
	for i,0,max_id2,1
		objprm i+16,pre(i)
	next
		for i,0,max_id2,1
		objprm i+21,se(i)
	next
	for i,0,5,1
		objprm i+26,strf("%2.3f",border(i))
	next
	stop
;==========================================================
*start
	if (strlen(filename(1))<=4)&(ki!=1):dialog "出力ファイルを設定してください",1,"":goto *file_save
	sr(6)=sr(0)+sr(1)+sr(2)+sr(3)+sr(4)
	time(0)=gettime(0)*365*30*3600*24+gettime(1)*30*3600*24+gettime(3)*3600*24+gettime(4)*3600+gettime(5)*60+gettime(6)
	if sr(6)==0:dialog "検索するIDを選択してください",1,"":stop
	if (ki==1)&(sor==3):dialog "単月出力では平均点順ソートは使えません",1,"":stop
	for i,0,43,1
		objgray i,0;停止ボタン以外を無効化
	next
	for chc,0,5,1
		if sr(chc)==1:ser=chc:_break;追記の名前決定
	next
	title "メモリ確保中..."
	max_id3=1000+500*sr(11)
	;配列形式 配列名(曲ID,データファイルNo.[集計期間ヶ月])	
	sdim n1,4;リクエストNo.上4桁
	sdim n2,2;リクエストNo.下2桁
	sdim son,10;song name(曲名)
	sdim art,10;artist(アーティスト名)
	dimtype limit100,vartype("int"),m;旧バージョンのデータファイルか
	dimtype ar,vartype("int"),max_id3,m;all ranker(全歌唱者数)
	dimtype rank,vartype("int"),max_id3,m;rank(順位)
	ddim poi,max_id3,m;point(得点)
	sdim top3,20,max_id3,m,6
	dim no_detect,max_id3;未検出があったかどうかのフラグ
	sdim rbn,50,max_id

	;完全一致検索の準備
	for i,0,max_id,1
		rbn(i)=rn(i)
		for k,0,16-strlen(rn(i)),1: rbn(i)=rbn(i)+" ": next
	next
	;ファイルを開く
		id=0:fl=0
		for mo,0,m,1
			exist datafile(mo)
			alloc buf,strsize
			notesel buf
			noteload datafile(mo)
			notesel_fast buf
			if strmid(datafile(mo),-1,4)=".dat":datatype=0:gosub *dataload
			if (strmid(datafile(mo),-1,4)="html")|(strmid(datafile(mo),-1,4)=".htm"):datatype=1:gosub *htmlload
		next
		gosub *hand
		goto *sort
		stop
;===========================================================================
*dataload
	;曲情報の処理
			noteget_fast con,0
			if con=="#DATAFILE ver.1.00#" {
				limit100(mo)=0
				scr_st = 9
				id_st = 18
			} else {
				limit100(mo)=1
				scr_st = 6
				id_st = 15
			}

			dim sea,5
			x=2;行カーソル
			do  
				noteget_fast con,1+x
				n1(id)=strmid (con,0,4);リクエストNo.の取得
				n2(id)=strmid (con,5,2);
				;曲名取得
				noteget_fast con,2+x:son(id)=con
				;アーティスト名取得
				noteget_fast con,3+x:art(id)=con
				;全歌唱者数取得
				noteget_fast con,5+x:ar(id,mo)=int(con)
				;上位ランカーの得点とID取得(単月出力のみ)
				if (ki==1)||(ki==3) {
					noteget_fast con,6+x
					top3(id,mo,0)=strmid(con,scr_st,6);1位の得点
					top3(id,mo,1)=strmid(con,id_st,16);1位のID
					if ar(id,mo)>=2 {
						noteget_fast con,7+x
						top3(id,mo,2)=strmid(con,scr_st,6);2位の得点
						top3(id,mo,3)=strmid(con,id_st,16);2位のID
					}
					if ar(id,mo)>=3 {
						noteget_fast con,8+x
						top3(id,mo,4)=strmid(con,scr_st,6);3位の得点
						top3(id,mo,5)=strmid(con,id_st,16);3位のID
					}
				}
				;順位・得点検索
				for y,0,ar(id,mo)+1,1
					noteget_fast con,(x+5)+y
					for i,0,max_id,1
#if 0
						;拡張IDモードOFF
						if (ser_mode==0) & ((sr(i)==1) & (strmid(con,id_st,16)==rbn(i)) & (instr(con,0,pre(i))!=-1) & (instr(con,0,se(i))!=-1)) {
							if poi(id,mo)<double(strmid(con,scr_st,6)) {
								poi(id,mo)=double(strmid(con,scr_st,6));文字列読み込み ＋ 実数化
								rank(id,mo)=int(y)
							}
						}
						;拡張IDモードON
						if (ser_mode==1) & ((strmid(con,id_st,16)==rbn(i)) & (instr(con,0,pre(i))!=-1) & (instr(con,0,se(i))!=-1)) {
							if poi(id,mo)<double(strmid(con,scr_st,6)) {
								poi(id,mo)=double(strmid(con,scr_st,6));文字列読み込み ＋ 実数化
								rank(id,mo)=int(y)
							}
						}
#else
						;ランバトネーム、都道府県、性別の比較回数を減らして高速化
						if (strmid(con,id_st,16)==rbn(i)) & (instr(con,0,pre(i))!=-1) & (instr(con,0,se(i))!=-1) {
;							if (ser_mode==1) || (sr(i)==1) {	;v0.932で置換
							if (ser_mode==1) | (sr(0)==1) | (sr(1)==1) | (sr(2)==1) | (sr(3)==1) | (sr(4)==1) {
								if poi(id,mo)<double(strmid(con,scr_st,6)) {
									poi(id,mo)=double(strmid(con,scr_st,6));文字列読み込み ＋ 実数化
									rank(id,mo)=int(y)
								}
							}
						}
#endif
					next
				next
				if rank(id,mo)==0: no_detect(mo)=1;未検出だったらフラグを立てる

				x=(x+5)+ar(id,mo)+1;行カーソル移動
				if id!=0:gosub *check
				if fl=0:id=id+1
				title "現在処理中:"+(mo+1)+"ファイル目:"+(x+1)+"/"+notemax_fast+":"+id+"曲検出"
				await wait_time(sr(10))
			until x>=notemax_fast-1
			return
;================================================================================
*htmlload
	sdim cont,60000
	bload datafile(mo),cont ;入力htmlファイル 
	sdim output,60000 
	notesel output 

	sdim requestno,7 
	dim i 
	dim len 
	dim mainpointer 
	dim pointer
	dim fileinfo,24
	sdim s,256 
;	sdim ln,1024 
	limit100(mo)=0
	i = instr(cont,mainpointer,"<style TYPE=\"text\/css\">") ;htmlのver確認(CSSが内か外か) 
	if i != -1 : limit100(mo) = 1 ;ある場合は旧バージョン	

	noteadd "#DATAFILE#";datファイル書き出し
	fxtget fileinfo,datafile(mo);ファイルの更新タイムスタンプを取得
	noteadd "データ取得時刻:"+fileinfo(8)+"/"+fileinfo(9)+"/"+fileinfo(11)+"　"+fileinfo(12)+":"+fileinfo(13)
	noteadd "================================================"
	;HTML解析スタート
	mainpointer = 0 
	repeat 
		if (limit100(mo)==1) {
			i = instr(cont,mainpointer,"class=\"score") ;得点データの前に必ずある文字列を検索 
			if i = -1 : break ;無かったら抜ける 
			pointer = mainpointer + i + 48 ;i の48文字先がデータの先頭 
			len = instr(cont,pointer,"<") ;データは"<"まで 
			poi(id,mo) = double(strmid(cont,pointer,len)) ;得点データ取得 

			i = instr(cont,mainpointer,"class=\"rank") 
			pointer = mainpointer + i + 40 
			len = instr(cont,pointer,"<") 
			rank(id,mo) = int(strmid(cont,pointer,len)) ;数値以外には０が入る 

			i = instr(cont,mainpointer,"request_no="); 
			pointer = mainpointer + i + 11 
			len = instr(cont,pointer,"\"") 
			requestno = strmid(cont,pointer,len) 
			n1(id)=strmid (requestno,0,4);リクエストNo.の取得
			n2(id)=strmid (requestno,5,2);


			i = instr(cont,mainpointer,"<td rowspan=1 class=\"up\">");曲タイトル 
			pointer = mainpointer + i + 25 
			len = instr(cont,pointer,"<") 
			son(id) = strmid(cont,pointer,len) 

;			if (ki==1)||(ki==3) {
				i = instr(cont,mainpointer,"1位【") 
				pointer = mainpointer + i + 5 
				len = instr(cont,pointer,"点】") 
				top3(id,mo,0) = strmid(cont,pointer,6);1位の得点 
				top3(id,mo,1)=strmid(cont,pointer+14,16);1位のランバトネーム
				i = instr(cont,mainpointer,"2位【") 
				pointer = mainpointer + i + 5 
				len = instr(cont,pointer,"点】") 
				top3(id,mo,2) = strmid(cont,pointer,6);2位の得点 
				top3(id,mo,3)=strmid(cont,pointer+10,16);2位のランバトネーム
;			}

			i = instr(cont,mainpointer,"class=\"down\">/") 
			pointer = mainpointer + i 
			i = instr(cont,pointer,"/")  ;"/"の3つ後から"<"までを取得。
			pointer = pointer + i + 3        ;
			len = instr(cont,pointer,"<"); 
			s = strmid(cont,pointer,len) 
			ar(id,mo) = int(s)
			if (ar(id,mo)==0) {
				i = instr(cont,mainpointer,"class=\"down\">/") 
				pointer = mainpointer + i 
				i = instr(cont,pointer,"/")  ;"/"の2つ後から"<"までを取得。
				pointer = pointer + i + 2    ;
				len = instr(cont,pointer,"<"); 
				s = strmid(cont,pointer,len) 
			if (s = "100+"){ ;100+表記対応 
				ar(id,mo) = 100
				if (poi(id,mo)>0)&(rank(id,mo)==0):rank(id,mo)=101:ar(id,mo)=101
			}else{ 
				ar(id,mo) = int(s) 
			}

			}
		
			i = instr(cont,mainpointer,"<td rowspan=1 class=\"down\">") 
			pointer = mainpointer + i + 27 
			len = instr(cont,pointer,"<") 
			art(id) = strmid(cont,pointer,len);アーティスト名取得

;			if (ki==1)||(ki==3) {
				i = instr(cont,mainpointer,"3位【") 
				pointer = mainpointer + i + 5 
				len = instr(cont,pointer,"点】") 
				top3(id,mo,4)=strmid(cont,pointer,6);3位の得点
				top3(id,mo,5)=strmid(cont,pointer+10,16);3位のランバトネーム
;			}
		
		}else{
			;v1.0以降のHTML
			
			i = instr(cont,mainpointer,"class=\"MS") ;得点データの前に必ずある文字列を検索 
			if i = -1 : break ;無かったら抜ける 
			pointer = mainpointer + i + 12 ;i の12文字先がデータの先頭 
			len = instr(cont,pointer,"<") ;データは"<"まで 
			poi(id,mo) = double(strmid(cont,pointer,len)) ;得点データ取得 

			i = instr(cont,mainpointer,"class=\"MR") 
			pointer = mainpointer + i + 12 
			len = instr(cont,pointer,"<") 
			rank(id,mo) = int(strmid(cont,pointer,len)) ;数値以外には０が入る 

			i = instr(cont,mainpointer,"request_no="); 
			pointer = mainpointer + i + 11 
			len = instr(cont,pointer,"\"") 
			requestno = strmid(cont,pointer,len) 
			n1(id)=strmid (requestno,0,4);リクエストNo.の取得
			n2(id)=strmid (requestno,5,2);


			i = instr(cont,mainpointer,"class=\"sng\"");曲タイトル 
			pointer = mainpointer + i + 12 
			len = instr(cont,pointer,"<") 
			son(id) = strmid(cont,pointer,len) 

;			if (ki==1)||(ki==3) {
				i = instr(cont,mainpointer,"class=\"TR1\"") 
				pointer = mainpointer + i + 19 
				len = instr(cont,pointer,"点】") 
				top3(id,mo,0) = strmid(cont,pointer,6);1位の得点
				top3(id,mo,1)=strmid(cont,pointer+14,16);1位のランバトネーム
				i = instr(cont,mainpointer,"class=\"TR2\"") 
				pointer = mainpointer + i + 19 
				top3(id,mo,2) = strmid(cont,pointer,6);2位の得点 
				top3(id,mo,3)=strmid(cont,pointer+14,16);2位のランバトネーム
				i = instr(cont,mainpointer,"class=\"TR3\"") 
				pointer = mainpointer + i + 19 
				top3(id,mo,4) = strmid(cont,pointer,6);3位の得点 
				top3(id,mo,5)=strmid(cont,pointer+14,16);3位のランバトネーム
;			}


			i = instr(cont,mainpointer,"class=\"RK") 
			pointer = mainpointer + i 
			i = instr(cont,pointer,"/")  ;"/"の1つ後から"<"までを取得。
			pointer = pointer + i + 1        ;
			len = instr(cont,pointer,"<"); 
			s = strmid(cont,pointer,len) 
			if (s = "100+"){ ;100+表記対応 
				ar(id,mo) = 100 
				if (poi(id,mo)>0)&(rank(id,mo)==0):rank(id,mo)=101:ar(id,mo)=101
			}else{ 
				ar(id,mo) = int(s) 
			}

			i = instr(cont,mainpointer,"class=\"sgr\"") 
			pointer = mainpointer + i + 12 
			len = instr(cont,pointer,"<") 
			art(id) = strmid(cont,pointer,len);アーティスト名取得

		}	
	;datファイル吐き出し
		noteadd n1(id)+"-"+n2(id)
		noteadd son(id)
		noteadd art(id)
		noteadd ""+fileinfo(8)+"/"+fileinfo(9)+"/"+fileinfo(11)+"　"+fileinfo(12)+":"+fileinfo(13)+""
		noteadd ""+ar(id,mo)+""
		noteadd "  1位|"+top3(id,mo,0)+"点|"+top3(id,mo,1)+"|        |    "
		noteadd "  2位|"+top3(id,mo,2)+"点|"+top3(id,mo,3)+"|        |    "
		noteadd "  3位|"+top3(id,mo,4)+"点|"+top3(id,mo,5)+"|        |    "
		for i,4,ar(id,mo)+1,1
			if i<=9:temp="  "
			if (i>=10)&(i<=99):temp=" "
			if i>=100:temp=""
			if i==rank(id,mo) {
				temp=temp+strf(""+i+"位|%2.3f点|"+rn(ser),poi(id,mo))		
				for k,0,16-strlen(rn(ser)),1: temp=temp+" ": next
				temp=temp+"|"+pre(ser)
				for k,0,8-strlen(pre(ser)),1: temp=temp+" ": next
				temp=temp+"|"+se(ser)
			}else{
				temp=temp+i+"位|      点|                |        |    "
			}
			noteadd temp
		next
		noteadd "================================================"
		await wait_time(sr(10))

		mainpointer = pointer
		if rank(id,mo)==0: no_detect(mo)=1;未検出だったらフラグを立てる
		if id!=0:gosub *check
		if fl=0:id=id+1
		title "現在処理中:"+(mo+1)+"ファイル目:"+id+"曲検出"

	loop
	await wait_time(sr(10))
	if month(mo)<10:notesave "output"+year(mo)+"0"+month(mo)+".dat" ;出力 
	if month(mo)>=10:notesave "output"+year(mo)+month(mo)+".dat" ;出力 
	return
;================================================================================
*check
;ID重複チェック
	fl=0;チェックフラグ
#if 0
	for cha,0,id,1
	if rank(cha,mo)>ar(cha,mo):poi(cha,mo)=0.000:rank(cha,mo)=0.000
#else
	;曲数が多くなるにつれて処理時間が次第に長くなっていくのを軽減
	if rank(id,mo)>ar(id,mo):poi(id,mo)=0.000:rank(id,mo)=0
	for cha,0,id,1
#endif
		if (n1(cha)==n1(id))&(n2(cha)==n2(id)) {;リクエストNo.が一致したとき		
			poi(cha,mo)=poi(id,mo)			;moは固定で小さい方の曲IDに月違いのデータを代入。
			rank(cha,mo)=rank(id,mo)		
			ar(cha,mo)=ar(id,mo)
			if (ki==1)||(ki==3) {
				top3(cha,mo,0)=top3(id,mo,0)
				top3(cha,mo,1)=top3(id,mo,1)
				top3(cha,mo,2)=top3(id,mo,2)
				top3(cha,mo,3)=top3(id,mo,3)
				top3(cha,mo,4)=top3(id,mo,4)
				top3(cha,mo,5)=top3(id,mo,5)
			}
			poi(id,mo)=0.000:rank(id,mo)=0:ar(id,mo)=0;代入元の配列内容クリア
			fl=1:_break
		}
	next
	return
;==========================================================================================
;未検出曲手入力
*hand
	for chb,0,m,1
//		flg=0
//		for i,0,id,1
//			if no_detect(i,chb)==1: flg=1
//		next
//		if flg==1 {
		if (no_detect(chb)==1)&&(limit100(chb)==1) {
			gsel 0,1
			gsel 2,2
			pos 10,25:mes ""+year(chb)+"年"+month(chb)+"月のランク外曲の点数入力方法を選択してください。"
			objprm 3,0;チェックボックスＯＦＦ
			if datatype==0:objgray 3,1;
			if datatype==1:add2dat=0:objgray 3,0;HTMLファイルの場合追記OFF
			stop
		}
*next_month
		gsel 3,-1
		gsel 2,0
		color 200,200,255:boxf 0,0,320,120;ウインドウid=2のフォーム消去
		color 0,0,0
	next
	gsel 0,1
	goto *sort
	stop
;=========================================================================================
*no_input	;入力しない
	gsel 0,1
	gsel 2,-1
	goto *next_month

*hand_input	;手入力
	gsel 2,-1
	gsel 3,1
	//データファイル追記が選択されている場合、データファイルをロード
	if add2dat==1 {
		exist datafile(chb)
		alloc w_buf,abs(double(strsize)*1.01)
		notesel w_buf
		noteload datafile(chb)
	}
	for cha,0,id,1
		if (poi(cha,chb)==0)&(rank(cha,chb)==0) {
//		if no_detect(cha,chb)==1 {
			objprm 0,poi(cha,chb)
			pos 10,10:mes ""+n1(cha)+"-"+n2(cha)+""
			pos 10,30:mes ""+son(cha)+"-"+art(cha)+""
			pos 10,50:mes ""+year(chb)+"年"+month(chb)+"月"
			pos 50,70:mes "点"
			t_n1=n1(cha): t_n2=n2(cha)	//データファイル追記用
			stop
*syori
			gsel 3,1
			color 200,200,255:boxf 0,0,320,150;ウインドウid=3のフォーム消去
			color 0,0,0
		}
	next
	if add2dat==1: notesave datafile(chb)	//データファイルを上書き
	goto *next_month

*file_input	;ファイル入力
	dialog "*",16
	if stat=0:stop
	gsel 2,-1
	gsel 0,1
	//データファイル追記が選択されている場合、データファイルをロード
	if add2dat==1 {
		exist datafile(chb)
		alloc w_buf,abs(double(strsize)*1.01)
		notesel w_buf
		noteload datafile(chb)
	}
	;月別得点ファイルの読み出し
	exist refstr
	alloc r_buf,strsize
	notesel r_buf
	noteload refstr
	;行の解析
	for i,0,notemax,1
		noteget con,i
		t_n1=strmid (con,0,4);リクエストNo.の取得
		t_n2=strmid (con,5,2);
		t_poi=double(strmid(con,8,6));点数の取得
		;ランク外ファイル内にそれより高い点数の同じ曲がないか調べる
		for chc,0,notemax,1
			noteget con,chc
			t_n3=strmid (con,0,4);リクエストNo.の取得
			t_n4=strmid (con,5,2);
			if (t_n3==t_n1)&(t_n4==t_n2) {
				if t_poi<double(strmid(con,8,6)):t_poi=double(strmid(con,8,6))
			}
		next
		for cha,0,id,1	;リクエストNo.からchaに当たる数値を探す
			if n1(cha)=t_n1 && n2(cha)=t_n2 {
				if t_poi>poi(cha,chb) {
//				if no_detect(cha,chb)==1 {
					poi(cha,chb)=t_poi
					rank(cha,chb)=101:ar(cha,chb)=101
					;データファイル追記処理
					if add2dat==1 {
						notesel w_buf
						gosub *rankout_add
						notesel r_buf
					}
				}
			}
		next
		title "ランク外ファイル解析中:"+i+"/"+notemax
	next
	//データファイルを上書き
	if add2dat==1 {
		notesel w_buf
		notesave datafile(chb)
	}
	goto *next_month
;=========================================================================================
*no_sing
	rank(cha,chb)=0:ar(cha,chb)=0:poi(cha,chb)=0.000
	goto *syori
*rank_out
	poi(cha,chb)=double(strmid(con,0,6));文字列読み込み ＋ 実数化
	if poi(cha,chb)==0:dialog "得点が入力されていません",1:stop
	rank(cha,chb)=101:ar(cha,chb)=101
	if add2dat==1: gosub *rankout_add	//データファイル追記処理
	goto *syori
*rankout_add
	x=2;行カーソル
	do
		noteget con,x+1
		if con==t_n1+"-"+t_n2 {	//リクエストNo.が一致
			noteadd "101",x+5,1	//全歌唱者数を上書き
			temp=strf("101位|%2.3f点|"+rn(ser),poi(cha,chb))
			for k,0,16-strlen(rn(ser)),1: temp=temp+" ": next
			temp=temp+"|"+pre(ser)
			for k,0,8-strlen(pre(ser)),1: temp=temp+" ": next
			temp=temp+"|"+se(ser)
			noteadd temp,x+5+rank(cha,chb),0	//ランクデータを追記
			_break
		}else {
			noteget con,x+5		//全歌唱者数を取得
			x=(x+5)+con+1		//リクエストNo.が不一致
		}
	until x>=notemax-1
	return
;==========================================================================================
*sort
	gsel 2,-1
	gsel 3,-1
	gsel 0,1
	;曲別最高点・平均点算出
	ddim max_point,id+10
	ddim min_point,id+10
	ddim avg,id+10
	dim mon,id+10
	for cha,0,id,1
		for chb,0,m,1
			if max_point(cha)<poi(cha,chb):max_point(cha)=poi(cha,chb);曲ごとの最高点をmax_point()に代入
			avg(cha)=avg(cha)+poi(cha,chb)
			if poi(cha,chb)>1:mon(cha)=mon(cha)+1
		next
	
		if mon(cha)!=0:avg(cha)=avg(cha)/mon(cha);平均
		if mon(cha)==0:avg(cha)=0.000
	next
	;最低点算出
	for cha,0,id,1
		for chb,0,m,1
			if min_point(cha)>poi(cha,chb):min_point(cha)=poi(cha,chb);曲ごとの最低点をmin_point()に代入
		next
	next

	;自己最高点・平均点の平均
	dim mon,m+2
	dim mont,1
	ddim mp_avg,1
	ddim av_avg,1
	ddim mon_avg,m
	for cha,0,id,1
		mp_avg=mp_avg+max_point(cha)
		if max_point(cha)>1:mon(0)=mon(0)+1
	next
	if mon(0)!=0:mp_avg=mp_avg/mon(0);mon(0);0点でない曲の数
	if mon(0)==0:mp_avg=0.000;mp_avg;自己最高点の平均
	for chb,0,m,1
		for cha,0,id,1
			mon_avg(chb)=mon_avg(chb)+poi(cha,chb)
			if poi(cha,chb)>1:mon(chb+2)=mon(chb+2)+1
		next
		mon(1)=mon(1)+mon(chb+2)
		av_avg=av_avg+mon_avg(chb)
		if mon(chb+2)!=0:mon_avg(chb)=mon_avg(chb)/mon(chb+2);月別平均
		if mon(chb+2)==0:mon_avg(chb)=0.000;月別平均
	next
	if mon(1)!=0:av_avg=av_avg/mon(1);mon(1)…0点でない全歌唱回数
	if mon(1)==0:av_avg=0.000;全平均点
	;インデックスソートの準備
	dim n,id;n(cha)=元のインデックス
	for cha,0,id,1;インデックスの初期化
		n(cha)=cha
	next
	if sor==0:goto *mp_sort
	if sor==1:goto *no_sort
	if sor==2:goto *art_sort
	if sor==3 && sr(7)==0:goto *avg_sort
	stop
*mp_sort
;最高点でソート
	for cha,0,id,1
		title "得点順でソート中:"+(cha+1)+"/"+id+""
		for chb,0,id,1
			if max_point(n(cha))>max_point(n(chb)) {
				t=n(cha)
				n(cha)=n(chb)
				n(chb)=t
			}
		next
	next
	if (ki==0)|(ki==3):goto *htmlsave_multi
	if ki==1:goto *htmlsave_simple
	if ki==2:goto *txtsave
	stop

*no_sort
	dim dum1
	dim dum2
;リクエストNo.でソート
	for cha,0,id,1
		dum1(cha)=int(n1(cha));ダミーに整数としてコピー
		dum2(cha)=int(n2(cha))
	next
	for cha,0,id,1
		title "リクエストNo.でソート中:"+(cha+1)+"/"+id+""
		for chb,0,id,1
			if dum1(n(cha))<dum1(n(chb)) {
				t=n(cha)
				n(cha)=n(chb)
				n(chb)=t
			}
			if (dum1(n(cha))==dum1(n(chb)))&(dum2(n(cha))<dum2(n(chb))) {
				t=n(cha)
				n(cha)=n(chb)
				n(chb)=t
			}
		next
	next
	if (ki==0)|(ki==3):goto *htmlsave_multi
	if ki==1:goto *htmlsave_simple
	if ki==2:goto *txtsave
	stop

*art_sort
	sdim dum1,100,id
	n3=0
;アーティスト名でソート
	alloc buff,50000
	notesel buff
	for cha,0,id,1
		noteadd art(cha),cha,1
	next
	pos 0,490:mes buff	
	sortnote buff,0
	for chb,1,id+1,1
		sortget n3,chb
		n(chb-1)=n3
	next
;同じアーティストをリクエストNo.でソート
	dim dum1
	dim dum2
	for cha,0,id,1
		dum1(cha)=int(n1(cha));ダミーに整数としてコピー
		dum2(cha)=int(n2(cha))
	next
	for cha,0,id,1
		title "アーティスト順でソート中:"+(cha+1)+"/"+id+""
		for chb,0,id,1
			if art(n(cha))==art(n(chb)) {
				if dum1(n(cha))<dum1(n(chb)) {
					t=n(cha)
					n(cha)=n(chb)
					n(chb)=t
				}
				if (dum1(n(cha))==dum1(n(chb)))&(dum2(n(cha))<dum2(n(chb))) {
					t=n(cha)
					n(cha)=n(chb)
					n(chb)=t
				}
			}
		next
	next
	if (ki==0)|(ki==3):goto *htmlsave_multi
	if ki==1:goto *htmlsave_simple
	if ki==2:goto *txtsave
	stop

*avg_sort
;平均点でソート
	for cha,0,id,1
		title "平均点順でソート中:"+(cha+1)+"/"+id+""
		for chb,0,id,1
			if avg(n(cha))>avg(n(chb)) {
				t=n(cha)
				n(cha)=n(chb)
				n(chb)=t
			}
		next
	next
	if (ki==0)|(ki==3):goto *htmlsave_multi
	if ki==2:goto *txtsave
	stop
;=============================================================================================
*htmlsave_multi
	alloc buff,100000
	notesel buff
	noteadd "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\""
	noteadd "\"http://www.w3.org/TR/html4/loose.dtd\">"
	noteadd "<html>"
	noteadd "<head>"
	noteadd "<meta http-equiv=\"Content-Type\""
	noteadd "content=\"text/html; charset=x-sjis\">"
	noteadd "<meta http-equiv=\"Content-Style-Type\" content=\"text/css\">"
	noteadd "<link href=\"list.css\" rel=\"stylesheet\" type=\"text/css\">"
	noteadd 	"<title>"+year(0)+"年"+month(0)+"月からのランバト全成績("+rn(ser)+")</title></head>"
	noteadd "<body>"
	noteadd "<hr>"
	noteadd filename(3)
	if gettime(5)<10 {
		noteadd "<br><br>更新時刻:"+gettime(0)+"/"+gettime(1)+"/"+gettime(3)+"　"+gettime(4)+":"+0+gettime(5)+""
		}
		else {
		noteadd "<br><br>更新時刻:"+gettime(0)+"/"+gettime(1)+"/"+gettime(3)+"　"+gettime(4)+":"+gettime(5)+""
	}
	if sr(7)==0:noteadd "<table width=\""+(1000-sr(8)*100+120)+"\">"
	if sr(7)==1:noteadd "<table width=\""+(1000-sr(8)*100)+"\">";平均点非表示
	noteadd "<tr>"
	noteadd "<th class=\"left\">自己最高点</th>"
	if sr(7)==0:noteadd "<th width=\"120\">平均点</th>"
	noteadd "<th colspan=2 class=\"side\">曲名/アーティスト</th>"

	sdim st,100,20
	for chb,0,m,1
		if chb==m-1:st(2)="class=\"right\""
		noteadd "<th "+st(2)+">'"+strmid(date(chb),2,2)+"/"+strmid(date(chb),-1,2)+"</th>"
	next
	noteadd "</tr>"
	for cha,0,id,1;各曲出力ループ開始
		title "HTML出力中:"+(cha+1)+"/"+id+""
		if (sr(9)==1)&(max_point(n(cha))==0.000) {
		}
		else {
			noteadd "<tr>"
			st(3)="5";初期値
			for i,0,5,1
				if max_point(n(cha))>=border(i):st(3)=str(i):_break;閾値判定
			next
			noteadd "<td rowspan=2 class=\"MS"+st(3)+"\">"+strf("%2.3f",max_point(n(cha)))+"<span class=\"ten\">点</span></td>";最高点
			if sr(7)==0:noteadd "<td rowspan=2 class=\"MS5\">"+strf("%2.3f",avg(n(cha)))+"<span class=\"ten\">点</span></td>";平均点
			noteadd "<td class=\"no\"> No."+(cha+1)+"</td>"
			noteadd "<td class=\"song\">"+son(n(cha))+"</td>";曲名
			for chb,0,m,1
				if chb==m-1:st(4)="L":else:st(4)=""
				if (max_point(n(cha))==poi(n(cha),chb))&(poi(n(cha),chb)>0):st(5)="M":else:st(5)=""
				if poi(n(cha),chb)==0 {
					noteadd "<td class=\"S"+st(4)+st(5)+"\">---</th>"
				}
				else {	
					noteadd "<td class=\"S"+st(4)+st(5)+"\">"+strf("%2.3f",poi(n(cha),chb))+"</td>"
				}
			next
			noteadd "</tr>"
			noteadd "<tr>"
			noteadd "<td class=\"id\">"
			if lin=0:noteadd DAM+n1(n(cha))+"-"+n2(n(cha))+"\" target=\"_blank\" title=\"\">"+n1(n(cha))+"-"+n2(n(cha))+"</a></td>"
			if lin=1:noteadd DAMk+n1(n(cha))+"-"+n2(n(cha))+"\" target=\"_blank\" title=\"\">"+n1(n(cha))+"-"+n2(n(cha))+"</a></td>"
			noteadd "<td class=\"singer\">"+art(n(cha))+"</td>"
			for chb,0,m,1
				if chb==m-1:st(4)="L":else:st(4)=""
				if rank(n(cha),chb)=1:st(6)="1";1位
				if rank(n(cha),chb)=2:st(6)="2";2位
				if rank(n(cha),chb)=3:st(6)="3";3位
				if (rank(n(cha),chb)>3)&(rank(n(cha),chb)<11):st(6)="4";4-10位
				if (rank(n(cha),chb)>10)|(rank(n(cha),chb)==0):st(6)="5";11-100位orランク外
				if ar(n(cha),chb)>=1 {
					if (ar(n(cha),chb)>=100) && (limit100(chb)==1) {
						;旧バージョンのデータの場合、100人以上は100
						st(7)="100"
					} else {
						;新バージョンのファイルか、1-100人まではそのまま記入
						st(7)=str(ar(n(cha),chb))
					}
				}
				if rank(n(cha),chb)==0 {
					noteadd "<td class=\"R"+st(4)+st(6)+"\">---</td>"					
				} else {
					if (rank(n(cha),chb)<=100) || (limit100(chb)==0) {
						noteadd "<td class=\"R"+st(4)+st(6)+"\">"+rank(n(cha),chb)+"<span class=\"ranker\">/"+st(7)+"</span></td>"
					} else {
						noteadd "<td class=\"R"+st(4)+st(6)+"\">--<span class=\"ranker\">/"+st(7)+"</span></td>"
					}
				}
			next
			noteadd "</tr>"
			noteadd "<tr></tr>"
		};if sr(9)...elseの条件終了
		await wait_time(sr(10))
	next;各曲出力ループ終了
	noteadd "</table><br>"
	if sr(7)==0:noteadd "<table width=\"820\">"
	if sr(7)==1:noteadd "<table width=\"700\">"
	noteadd "<tr>"
	noteadd "<th class=\"left\">平均自己最高点</th>"
	noteadd "<th class=\"left\">平均点</th>"
	sdim st,100,20
	for chb,0,m,1
		if chb==m-1:st(2)="class=\"right\""
		noteadd "<th "+st(2)+">'"+strmid(date(chb),2,2)+"/"+strmid(date(chb),-1,2)+"</th>"
	next
	noteadd "</tr><tr>"
	noteadd "<td rowspan=2 class=\"MS5\">"+strf("%2.3f",mp_avg)+"<span class=\"ten\">点</span></td>";平均点
	noteadd "<td rowspan=2 class=\"MS5\">"+strf("%2.3f",av_avg)+"<span class=\"ten\">点</span></td>";平均点
	for chb,0,m,1
		if chb==m-1:st(4)="L":else:st(4)=""
		noteadd "<td class=\"S"+st(4)+"\">"+strf("%2.3f",mon_avg(chb))+"</td>"
	next
	noteadd "</tr><tr>"
	for chb,0,m,1
		if chb==m-1:st(4)="L":else:st(4)=""
		noteadd "<td class=\"R"+st(4)+5+"\">"+mon(chb+2)+"曲</td>"
	next
	noteadd "</tr>"
	noteadd "</table><br>"
	noteadd "データ取得 by "+ranbatokun
	noteadd "集計 by "+ranbatohan
	noteadd filename(4)
	noteadd "<br><hr>"
	noteadd"</body></html>"
 	notesave filename(1)
	time(1)=gettime(0)*365*30*3600*24+gettime(1)*30*3600*24+gettime(3)*3600*24+gettime(4)*3600+gettime(5)*60+gettime(6)
 	dialog "ファイルを"+filename(1)+"に保存しました。\n経過時間"+(time(1)-time(0))+"秒",0,"出力終了"
 	title titl
 	if ki==3:goto *htmlsave_simple
	if (strlen(filename(0))>3)&(max_id==5):gosub *init_save
	goto *stop_routine
	stop
;======================================================================================================
*htmlsave_simple
	for cha,0,m,1
		dialog ""+year(cha)+"年"+month(cha)+"月の結果を出力しますか？",2,"単月出力"
		if stat==6 {
			dialog "html",17,"保存先の選択"
			if stat==1 { 
				filename(2)=refstr
				alloc buff,100000
				sdim st,10,5
				if ((ki==1)|(ki==3))&((sor==0)|(sor==3)) {
					for chc,0,id,1
						for chd,0,id,1
							if poi(n(chc),cha)>poi(n(chd),cha) {
								t=n(chc)
								n(chc)=n(chd)
								n(chd)=t
							}
						next
					next
				}
				notesel buff
				noteadd	"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\""
				noteadd "\"http://www.w3.org/TR/html4/loose.dtd\">"
				noteadd "<html>"
				noteadd "<head>"
				noteadd "<meta http-equiv=\"Content-Type\""
				noteadd "content=\"text/html\; charset=x-sjis\">"
				noteadd "<meta http-equiv=\"Content-Style-Type\" content=\"text/css\">"
				noteadd "<style TYPE=\"text/css\">"
				noteadd "<!--"
				noteadd "	b { color: Fuchsia; background-color:mistyrose;}"
				noteadd "	td {margine:0px\; border: 1px solid gray;padding: 2px\;background-color:lightcyan\;font-size: 12px\;}"
				noteadd "	th {margine:0px\; border: 1px solid gray\; border-top: 2px solid black\;padding: 2px;background-color:lightcyan\;font-size: 12px\;}"
				noteadd "	.red {color:red\; font-weight: bold\; }"
				noteadd "	span.ten{"
				noteadd "		font-size:16px\;"
				noteadd "		font-weight:bold\;"
				noteadd "	}"
				noteadd "	.score{"
				noteadd "		border-top: 2px solid black\;"
				noteadd	"		border-left: 2px solid black\;"
				noteadd "		border-bottom: 2px solid black\;"
				noteadd "		padding: 3px\;"
				noteadd "		background-color:#ccffff\;"
				noteadd "		font-size:32px\;"
				noteadd	"		text-align: center\;" 
				noteadd "	}"
				noteadd "	.rank1{"
				noteadd "		border-top: 2px solid black\;"
				noteadd	"		border-bottom: 2px solid black\;"
				noteadd	"		padding: 3px\;"
				noteadd	"		background-color:gold\;"
				noteadd "		font-size:32px\;"
				noteadd	"		text-align: center\;" 
				noteadd	"	}"
				noteadd "	.rank2{"
				noteadd "		border-top: 2px solid black\;"
				noteadd "		border-bottom: 2px solid black\;"
				noteadd "		padding: 3px\;"
				noteadd "		background-color:lightgrey\;"
				noteadd "		font-size:32px\;"
				noteadd "		text-align: center\;" 
				noteadd "	}"
				noteadd "	.rank3{"
				noteadd "		border-top: 2px solid black\;"
				noteadd "		border-bottom: 2px solid black\;"
				noteadd "		padding: 3px\;"
				noteadd "		background-color: sandybrown\;"
				noteadd "		font-size:32px\;"
				noteadd "		text-align: center\;" 
				noteadd "	}"
				noteadd "	.rank4{"
				noteadd "		border-top: 2px solid black\;"
				noteadd "		border-bottom: 2px solid black\;"
				noteadd "		padding: 3px\;"
				noteadd "		background-color: greenyellow\;"
				noteadd "		font-size:32px\;"
				noteadd "		text-align: center\;"
				noteadd "	}"
				noteadd "	.rank5{"
				noteadd "		border-top: 2px solid black\;"
				noteadd "		border-bottom: 2px solid black\;"
				noteadd "		padding: 3px\;"
				noteadd "		background-color:#ccffff\;"
				noteadd "		font-size:32px\;"
				noteadd "		text-align: center\;" 
				noteadd "	}"
				noteadd "	.up{"
				noteadd "		border-top: 2px solid black\;"
				noteadd "	}"
				noteadd "	.down{"
				noteadd "		border-bottom: 2px solid black\;"
				noteadd "	}"
				noteadd "	.toprank1{"
				noteadd "		background-color: gold\;"
				noteadd "		border-right: 2px solid black\;"
				noteadd "	}"
				noteadd "	.toprank2{"
				noteadd "		background-color: lightgrey\;"
				noteadd "		border-right: 2px solid black\;"
				noteadd "	}"
				noteadd "	.toprank3{"
				noteadd "		background-color: sandybrown\;"
				noteadd "		border-right: 2px solid black\;"
				noteadd "	}"
				noteadd "	table{"
				noteadd "		border-collapse: collapse\;" 
				noteadd "	}"
				noteadd "	-->"
				noteadd "	</style>"
				noteadd "	<title>"
				noteadd ""+strmid(date(cha),2,2)+"年"+strmid(date(cha),-1,2)+"月のランバト成績("+rn(ser)+")</title></head>"
				noteadd "<body><hr>"
				noteadd filename(3)
				if gettime(5)<10 {
					noteadd "<br><br>データ更新時刻:"+gettime(0)+"/"+gettime(1)+"/"+gettime(3)+"　"+gettime(4)+":"+0+gettime(5)+"<table width=\""+(1000-sr(8)*100)+"\"><tr><th style=\"border-left: 2px solid black\;\">今月の最高点</th><th>順位</th><th style=\"font-size:10px\;\">曲番/人数</th><th>楽曲情報</th><th colspan=2 style=\"border-right: 2px solid black\;\">上位ランカー</th></tr>"
				}
				else {
					noteadd "<br><br>データ更新時刻:"+gettime(0)+"/"+gettime(1)+"/"+gettime(3)+"　"+gettime(4)+":"+gettime(5)+"<table width=\""+(1000-sr(8)*100)+"\"><tr><th style=\"border-left: 2px solid black\;\">今月の最高点</th><th>順位</th><th style=\"font-size:10px\;\">曲番/人数</th><th>楽曲情報</th><th colspan=2 style=\"border-right: 2px solid black\;\">上位ランカー</th></tr>"
				}
				for chb,0,id,1
					if ((poi(n(chb),cha)==0.000)&(sr(9)==1))|(strlen(top3(n(chb),cha,0))<3) {
					}
					else {
						st(0)="5"
						for i,0,5,1
							if poi(n(chb),cha)>=border(i):st(0)=str(i):_break;閾値判定
						next
						if st(0)=="0":st(1)="#FF0000"
						if st(0)=="1":st(1)="#FF6060"
						if st(0)=="2":st(1)="#FF8080"
						if st(0)=="3":st(1)="#FFB0B0"
						if st(0)=="4":st(1)="#FFD0D0"
						if st(0)=="5":st(1)="#FFF0F0"
						if rank(n(chb),cha)==1:st(2)="1"
						if rank(n(chb),cha)==2:st(2)="2"
						if rank(n(chb),cha)==3:st(2)="3"
						if (rank(n(chb),cha)>3)&(rank(n(chb),cha)<11):st(2)="4"
						if rank(n(chb),cha)>10:st(2)="5"

						temp=""
						temp=temp+"<tr><td rowspan=2 class=\"score\" style=\"background-color:"+st(1)+"\;\">"+strf("%2.3f",poi(n(chb),cha))+"<span class=\"ten\">点</span></td>"
						if ((limit100(cha)==0)||(rank(n(chb),cha)<=100))&&(rank(n(chb),cha)!=0):temp=temp+"<td rowspan=2 class=\"rank"+st(2)+"\" style=\"padding:3px 20px\;\">"+rank(n(chb),cha)+"</td><td rowspan=1 style=\"text-align: center\;\" class=\"up\">"
						if ((limit100(cha)==1)&&(rank(n(chb),cha)>100))||(rank(n(chb),cha)==0):temp=temp+"<td rowspan=2 class=\"rank5\" style=\"padding:3px 20px\;\">--</td><td rowspan=1 style=\"text-align: center\;\" class=\"up\">"
						if lin=0:temp=temp+DAM+n1(n(chb))+"-"+n2(n(chb))+"\" target=\"_blank\" title=\"\">"+n1(n(chb))+"-"+n2(n(chb))+"</a></td>"
						if lin=1:temp=temp+DAMk+n1(n(chb))+"-"+n2(n(chb))+"\" target=\"_blank\" title=\"\">"+n1(n(chb))+"-"+n2(n(chb))+"</a></td>"
						temp=temp+"<td rowspan=1 class=\"up\">"+son(n(chb))+"</td><td rowspan=2 class=\"up\" style=\"background-color:gold\;border-right: 2px solid black\;border-left: 2px solid black\;\">  1位【"+top3(n(chb),cha,0)+"点】<br>"+top3(n(chb),cha,1)+"</td>"
						if ar(n(chb),cha)>=2:temp=temp+"<td rowspan=1 class=\"up\" style=\"font-size: 10px;background-color:lightgrey\;border-right: 2px solid black\;\">  2位【"+top3(n(chb),cha,2)+"点】"+top3(n(chb),cha,3)+"</td></tr>"
						if ar(n(chb),cha)<2:temp=temp+"<td rowspan=1 class=\"up\" style=\"font-size: 10px;border-right: 2px solid black\;\"></td></tr>"
						if ar(n(chb),cha)<100:temp=temp+"<tr><td rowspan=1 style=\"font-size: 14px\;\" class=\"down\">/　"+ar(n(chb),cha)+"</td><td rowspan=1 class=\"down\">"+art(n(chb))+"</td>"
						if (limit100(cha)==0)&&(ar(n(chb),cha)>=100):temp=temp+"<tr><td rowspan=1 style=\"font-size: 14px\;font-weight:bold\;color:red\;\" class=\"down\">/ "+ar(n(chb),cha)+"</td><td rowspan=1 class=\"down\">"+art(n(chb))+"</td>"
						if (limit100(cha)==1)&&(ar(n(chb),cha)>=100):temp=temp+"<tr><td rowspan=1 style=\"font-size: 14px\;font-weight:bold\;color:red\;\" class=\"down\">/ 100+</td><td rowspan=1 class=\"down\">"+art(n(chb))+"</td>"
						if ar(n(chb),cha)>=3:temp=temp+"<td rowspan=1 class=\"down\" style=\"font-size: 10px\;background-color:sandybrown\;border-right: 2px solid black\;\">  3位【"+top3(n(chb),cha,4)+"点】"+top3(n(chb),cha,5)+"</td></tr><tr></tr>"
						if ar(n(chb),cha)<3:temp=temp+"<td rowspan=1 class=\"down\" style=\"font-size: 10px\;border-right: 2px solid black\;\"></td></tr><tr></tr>"
						noteadd temp
					}
					await wait_time(sr(10))
					title "HTML出力中:"+(chb+1)+"/"+id+""
				next
				noteadd	"</table><br>"
				noteadd "集計 by "+ranbatokun
				noteadd "編集 by "+ranbatohan
				noteadd filename(4)
				noteadd "<br><hr>"
				noteadd "</body>"
				noteadd "</html>"
				notesave filename(2)
				time(1)=gettime(0)*365*30*3600*24+gettime(1)*30*3600*24+gettime(3)*3600*24+gettime(4)*3600+gettime(5)*60+gettime(6)
			 	dialog "ファイルを"+filename(2)+"に保存しました。\n経過時間"+(time(1)-time(0))+"秒",0,"出力終了"

			}
		}
	next
	if (strlen(filename(0))>3)&(max_id==5):gosub *init_save 
	goto *stop_routine
	stop
;======================================================================================================
*txtsave
	alloc buff,10000
	notesel buff
	for cha,0,id,1
		noteadd ""+n1(cha)+"-"+n2(cha)+"",,0
		noteadd son(cha),,0
		noteadd art(cha),,0
		for chb,0,m,1
			noteadd ""+int(year(chb))+"年"+int(month(chb))+"月",,0
			noteadd ""+strf("%2.3f点",poi(cha,chb))+":"+rank(cha,chb)+"位/"+ar(cha,chb)+"人中",,0
		next
	next
	notesave filename(1)
 	dialog "ファイルを"+filename(1)+"に保存しました。",0,"出力終了"
	if (strlen(filename(0))>3)&(max_id==5):gosub *init_save 
	goto *stop_routine
 	stop
;==============================================================================
*init_save
	alloc buff,10000
	notesel buff
	noteadd "「らんばとはん」v0.9x設定",0,1
;検索ID(1-5)
	for i,1,6,1
		noteadd rn(i-1),i,1
	next
;検索都道府県(6-10)
	for i,6,11,1
		noteadd pre(i-6),i,1
	next
;検索性別(11-15)
	for i,11,16,1
		noteadd se(i-11),i,1
	next
;得点配色閾値(16-20)
	for i,0,5,1
		borderm(i)=strf("%2.3f",border(i))
	next
	for i,16,21,1
		noteadd borderm(i-16),i,1
	next
;入力データファイル名
	for i,0,m,1
		if month(i)<10: noteadd ""+year(i)+"-"+"0"+month(i)+"",21+2*i,1
		if month(i)>=10:noteadd ""+year(i)+"-"+month(i)+"",21+2*i,1
		noteadd datafile(i),22+2*i
	next
	;設定ファイルチェック
	if notemax>=22:notesave filename(0)
	if notemax<22:dialog "データファイルが一つも指定されていないのでオートセーブをキャンセルします。"
	return
	stop
;==========================================================================================
*stop_routine
	title titl
	for i,0,43,1
		objgray i,1;オブジェクトを有効化
	next
	stop
;==========================================================================================
*end_routine
	if (strlen(filename(0))>3)&(max_id==5):gosub *init_save 
	end
