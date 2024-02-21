drop database if exists dbProject100;
create database dbProject100;
use dbProject100;
create table data100(
    heartdisease varchar(5),
    BMI double,
    smoking varchar(5),
    alcohol varchar(5),
    stroke varchar(5),
    physicalheatlh int,
    mentalhealth int,
    diffwalking varchar(5),
    gender varchar(6),
    age varchar(20),
    race varchar(15),
    diabetes varchar(30),
    physicalactivity varchar(5),
    generalhealth varchar(10),
    sleeptime int,
    asthma varchar(5),
    penyakitginjal varchar(5),
    penyakitkanker varchar(5)
);
/*load data yang diambil dari 100 data teratas dari heart_cleaned_2020.csv*/
load data local infile 'D:/datamining/100data.csv'
into table data100
fields terminated by';'
enclosed by ''''
ignore 1 lines;
alter table data100 drop column physicalheatlh;
alter table data100 drop column mentalhealth;
alter table data100 drop column physicalactivity;
alter table data100 drop column penyakitkanker;
alter table data100 drop column race;
alter table data100 drop column diffwalking;
alter table data100 drop column penyakitginjal;
select count(*) from data100;

/*memasukan berat ke range*/
alter table data100 add column rangebmi varchar(20);
update data100 set rangebmi="25_sampai_50" where 25<BMI<50;
update data100 set rangebmi="kurang_dari_25" where BMI<25;
update data100 set rangebmi="lebih_dari_50" where BMI>50;
select * from data100 limit 5;

/*membuat range umur*/
alter table data100 add column rangeumur varchar(20);
update data100 set rangeumur="dibawah_50" where age="30-34" or 
age="35-39" or age="40-44" or age="45-49" or age="25-29"or age="18-24";   
update data100 set rangeumur="50_sampai_79" where age="50-54" or 
age="55-59" or age="60-64" or age="65-69" or age="70-74" or age="75-79"; 
update data100 set rangeumur="diatas_80" where age="80 or older";
select * from data100 limit 5;

/*meenjadikan diabetes menjadi yes dan no*/
alter table data100 add column simplediabetes varchar(20);
update data100 set simplediabetes="yes" where diabetes="yes" or 
diabetes="Yes (during pregnancy)" or diabetes="No, borderline diabetes";
update data100 set simplediabetes="no" where diabetes="no";

/*membuat range waktu tidur*/
alter table data100 add column waktutidur varchar(20);
update data100 set waktutidur="6_sampai_8" where 6<=sleeptime<=8;
update data100 set waktutidur="kurang_dari_6" where sleeptime<6;
update data100 set waktutidur="lebih_dari_8" where sleeptime>8;

alter table data100 drop column BMI;
alter table data100 drop column age;
alter table data100 drop column diabetes;
alter table data100 drop column sleeptime;

select* from data100 limit 5;
/*menhitung jumlah data, yes(penyakit jantung),tidak(tidak penyakit jantung) dan nilai I*/

create table tbliterasi(
        atribut varchar(20),
        informasi varchar(20),
        jumlahdata int,
        tidak int,
        ya int,
        nilaiI double,
        gain double
);

/*membuat procedure*/
delimiter &&
create procedure iter(dbname varchar(200))
begin
    /*mendefinisikan command, pengganti*/
    DECLARE command NVARCHAR(3000);
    declare pengganti nvarchar(3000);
    declare i int;
    declare atributs varchar(100);
    set i:=0;
    /*mengosongkan tbliterasi*/
    truncate tbliterasi;
    /*set command untuk menghitung jumlah data*/
    set command:=concat('select @jumlah_data:=count(*)from ',dbname);
    PREPARE stmt2 FROM command;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;
    /*set command untuk menghitung jumlah data yes*/
    set command:=concat('select @yes:=count(*)from ',dbname,' where heartdisease="yes";');
    PREPARE stmt2 FROM command;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;
    /*set command untuk menghitung jumlah data no*/
    set command:=concat('select @no:=count(*)from ',dbname,' where heartdisease="no";');
    PREPARE stmt2 FROM command;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;
    select @nilaiI:=(-(@no/@jumlah_data)*log2(@no/@jumlah_data))
    +(-(@yes/@jumlah_data)*log2(@yes/@jumlah_data))as inf;
    insert into tbliterasi(atribut,jumlahdata, tidak, ya,nilaiI) values
    ('total data',@jumlah_data,@no,@yes,@nilaiI);
    atribute: while i<>10 do 
        /*setting atribut yang ingin dipanggil*/
        if(i=0) then
            set atributs='rangebmi';
        else
            if(i=1)then set atributs='smoking';
            else 
                if(i=2) then set atributs='alcohol';
                else
                    if(i=3) then set atributs='stroke';
                    else 
                        if(i=4) then set atributs='gender';
                        else 
                            if(i=5)then set atributs='rangeumur';
                            else 
                                if(i=6) then set atributs='simplediabetes';
                                else 
                                    if(i=7) then set atributs='generalhealth';
                                    else 
                                        if(i=8) then set atributs='waktutidur';
                                        else 
                                            set atributs='asthma';
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;  
        /*setting command untuk memasukan ke table iterasi sesuai group atribut 
        dan menghitung jumlah data,jumlah ya, jumlah tidak sesuai dengan group informasi atribut */
        set command:= concat('insert into tbliterasi( informasi,jumlahdata, tidak,ya) select a.',atributs,'
        , count(*)as jumlahdata, (select count(*) from ',dbname,' as b where b.heartdisease="no" and 
        b.',atributs,'=a.',atributs,')as jawabno,(select count(*)from ',dbname,' as c where c.heartdisease
        ="yes" and c.',atributs,'=a.',atributs,')as jawabyes from ',dbname,' as a group by a.',atributs,';') ;
        /*setting pengganti untuk memberi nama atribut pada table iterasi */
        set pengganti:=concat('update tbliterasi set atribut ="',atributs,'" where atribut is null;');
        /*menyiapakan(prepare) statement untuk command dan atribut*/
        PREPARE stmt from pengganti;
        PREPARE stmt2 FROM command;
        /*menjalankan statement*/
        EXECUTE stmt2;
        EXECUTE stmt;
        /*melepas prepare statement*/
        DEALLOCATE PREPARE stmt;
        DEALLOCATE PREPARE stmt2;
        set i:=i+1;
    end while atribute;
    /*menghitung nilai informasi */
    update tbliterasi set nilaiI=
    (-(tidak/jumlahdata)*log2(tidak/jumlahdata))+
    (-(ya/jumlahdata)*log2(ya/jumlahdata));
    /*membuat tabel sementara*/
    drop table if EXISTS tbltampung;
    create temporary table tbltampung(
    atribut varchar(20),
    gain double
    );
    /*copy atribut dari tblhitung ke tbltampung dan menghitung nilai gain*/
    
    update tbliterasi set nilaiI=0 where nilaiI is null;
    insert into tbltampung (atribut,gain)
    select atribut,@nilaiI-sum((jumlahdata/@jumlah_data)*nilaiI) as nilaigain from tbliterasi group by atribut;
    update tbliterasi set gain=(select gain from tbltampung where tbltampung.atribut=tbliterasi.atribut);
    update tbliterasi set nilaiI=round(nilaiI,3);
    update tbliterasi set gain=round(gain,3);
    select dbname;
    select * from tbliterasi;
end; &&
delimiter ;
/*memanggil procedure dengan data 100*/
call iter('data100');

/*membuat table dengan general health good dari data 100 lalu memanggil procedure*/
create table data100_2_generalheatlh_good like data100;
insert into data100_2_generalheatlh_good select* from data100 where generalhealth="good";
call iter('data100_2_generalheatlh_good');

/*membuat table dengan general health fair dari data 100 lalu memanggil procedure*/
create table data100_2_generalheatlh_fair like data100;
insert into data100_2_generalheatlh_fair select* from data100 where generalhealth="fair";
call iter('data100_2_generalheatlh_fair');

/*membuat table dengan general health poor dari data 100 lalu memanggil procedure*/
create table data100_2_generalheatlh_poor like data100;
insert into data100_2_generalheatlh_poor select* from data100 where generalhealth="poor";
call iter('data100_2_generalheatlh_poor');

/*membuat table dengan smoking no dari general health good lalu memanggil procedure*/
create table data100_3_generalheatlh_good_smoking_no like data100;
insert into data100_3_generalheatlh_good_smoking_no
select* from data100_2_generalheatlh_good where smoking="no";
call iter('data100_3_generalheatlh_good_smoking_no');

/*membuat table dengan sleep 6-8 dari general health fair lalu memanggil procedure*/
create table data100_3_generalheatlh_fair_sleep_6s8 like data100;
insert into data100_3_generalheatlh_fair_sleep_6s8 
select* from data100_2_generalheatlh_fair where waktutidur="6_sampai_8";
call iter('data100_3_generalheatlh_fair_sleep_6s8');

/*membuat table dengan sleep lebih dari 8 dari general health fair lalu memanggil procedure*/
create table data100_3_generalheatlh_fair_sleep_l8 like data100;
insert into data100_3_generalheatlh_fair_sleep_l8 
select* from data100_2_generalheatlh_fair where waktutidur="lebih_dari_8";
call iter('data100_3_generalheatlh_fair_sleep_l8');

/*membuat table dengan bmi 25-50 dari general health good, smoking no  lalu memanggil procedure*/
create table data100_4_generalheatlh_good_smoking_no_bmi_25s50 like data100;
insert into data100_4_generalheatlh_good_smoking_no_bmi_25s50
select* from data100_3_generalheatlh_good_smoking_no where rangebmi="25_sampai_50";
call iter('data100_4_generalheatlh_good_smoking_no_bmi_25s50');

/*membuat table dengan gender female dari general health good, smoking no  lalu memanggil procedure*/
create table data100_4_generalheatlh_good_smoking_no_gender_female like data100;
insert into data100_4_generalheatlh_good_smoking_no_gender_female
select* from data100_3_generalheatlh_good_smoking_no where gender="female";
call iter('data100_4_generalheatlh_good_smoking_no_gender_female');

/*membuat table dengan gender female dari general health fair, sleep 6-8  lalu memanggil procedure*/
create table data100_4_generalheatlh_fair_sleep_6s8_gender_female like data100;
insert into data100_4_generalheatlh_fair_sleep_6s8_gender_female 
select* from data100_3_generalheatlh_fair_sleep_6s8 where gender="female";
call iter('data100_4_generalheatlh_fair_sleep_6s8_gender_female');

/*membuat table dengan diabetes yes dari general health fair, sleep 6-8  lalu memanggil procedure*/
create table data100_4_generalheatlh_fair_sleep_6s8_diabetes_yes like data100;
insert into data100_4_generalheatlh_fair_sleep_6s8_diabetes_yes 
select* from data100_3_generalheatlh_fair_sleep_6s8 where simplediabetes="yes";
call iter('data100_4_generalheatlh_fair_sleep_6s8_diabetes_yes');

/*membuat table dengan gender female dari general health good, 
smoking no, bmi 25-50  lalu memanggil procedure*/
create table data100_5_generalheatlh_good_smoking_no_bmi_25s50_gender_female like data100;
insert into data100_5_generalheatlh_good_smoking_no_bmi_25s50_gender_female
select* from data100_4_generalheatlh_good_smoking_no_bmi_25s50 where gender="female";
call iter('data100_5_generalheatlh_good_smoking_no_bmi_25s50_gender_female');

/*membuat table dengan bmi 25-50 dari general health good, 
smoking no, gender female  lalu memanggil procedure*/
create table data100_5_generalheatlh_good_smoking_no_gender_female_bmi_25s50 like data100;
insert into data100_5_generalheatlh_good_smoking_no_gender_female_bmi_25s50
select* from data100_4_generalheatlh_good_smoking_no_gender_female where rangebmi="25_sampai_50";
call iter('data100_5_generalheatlh_good_smoking_no_gender_female_bmi_25s50');

/*membuat table dengan sleep 6-8 dari general health good, 
smoking no, bmi 25-50, gender female  lalu memanggil procedure*/
create table data100_6_gh_good_smoking_no_bmi_25s50_gender_female_sleep_6s8 like data100;
insert into data100_6_gh_good_smoking_no_bmi_25s50_gender_female_sleep_6s8
select* from data100_5_generalheatlh_good_smoking_no_bmi_25s50_gender_female where waktutidur="6_sampai_8";
call iter('data100_6_gh_good_smoking_no_bmi_25s50_gender_female_sleep_6s8');

/*membuat table dengan sleep 6-8 dari general health good, 
smoking no, gender female, bmi 25-50 lalu memanggil procedure*/
create table data100_6_gh_good_smoking_no_gender_female_bmi_25s50_sleep_6s8 like data100;
insert into data100_6_gh_good_smoking_no_gender_female_bmi_25s50_sleep_6s8
select* from data100_5_generalheatlh_good_smoking_no_gender_female_bmi_25s50 where waktutidur="6_sampai_8";
call iter('data100_6_gh_good_smoking_no_gender_female_bmi_25s50_sleep_6s8');

/*membuat table dengan diabetes no dari general health good, 
smoking no, bmi 25-50, gender female, sleep 6-8 lalu memanggil procedure*/
create table d_7_gh_good_smo_no_bmi_25s50_gdr_f_sleep_6s8_diabet_no like data100;
insert into d_7_gh_good_smo_no_bmi_25s50_gdr_f_sleep_6s8_diabet_no
select* from data100_6_gh_good_smoking_no_bmi_25s50_gender_female_sleep_6s8 where simplediabetes="no";
call iter('d_7_gh_good_smo_no_bmi_25s50_gdr_f_sleep_6s8_diabet_no');

/*membuat table dengan diabetes no dari general health good, 
smoking no, gender female, bmi 25-50, sleep 6-8 lalu memanggil procedure*/
create table d_7_gh_good_smo_no_gdr_f_bmi_25s50_sleep_6s8_diabet_no like data100;
insert into d_7_gh_good_smo_no_gdr_f_bmi_25s50_sleep_6s8_diabet_no
select* from data100_6_gh_good_smoking_no_gender_female_bmi_25s50_sleep_6s8 where simplediabetes="no";
call iter('d_7_gh_good_smo_no_gdr_f_bmi_25s50_sleep_6s8_diabet_no');

/*membuat table dengan umur 50-79 dari general health good, 
smoking no, bmi 25-50, gender female, sleep 6-8, diabetes no lalu memanggil procedure*/
create table d_8_gh_good_smo_no_bmi_25s50_gdr_f_sleep_6s8_diabet_no_u_50s79 like data100;
insert into d_8_gh_good_smo_no_bmi_25s50_gdr_f_sleep_6s8_diabet_no_u_50s79
select* from d_7_gh_good_smo_no_bmi_25s50_gdr_f_sleep_6s8_diabet_no where rangeumur="50_sampai_79";
call iter('d_8_gh_good_smo_no_bmi_25s50_gdr_f_sleep_6s8_diabet_no_u_50s79');

/*membuat table dengan umur 50-79 dari general health good, 
smoking no, gender female, bmi 25-50, sleep 6-8, diabetes no lalu memanggil procedure*/
create table d_8_gh_good_smo_no_gdr_f_bmi_25s50_sleep_6s8_diabet_no_u_50s79 like data100;
insert into d_8_gh_good_smo_no_gdr_f_bmi_25s50_sleep_6s8_diabet_no_u_50s79
select* from data100_6_gh_good_smoking_no_gender_female_bmi_25s50_sleep_6s8 where rangeumur="50_sampai_79";
call iter('d_8_gh_good_smo_no_gdr_f_bmi_25s50_sleep_6s8_diabet_no_u_50s79');