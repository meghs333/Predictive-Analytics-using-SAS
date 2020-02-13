LIBNAME UTD 'E:\New folder'; run;

data x;
set UTD.tgif;
run;

proc print data = x(obs=5);
run;


* removing variables with 0 values;

proc sql;
alter table x drop 
rest_loc_Merch,
rest_loc_Open,
rest_loc_Patio, 
rest_loc_cafe,
rest_loc_unkn, 
time_unknown,
disc_employee,
disc_type_empl,
disc_chan_comp,
disc_chan_entbk,
disc_chan_laten,
disc_chan_part,
disc_chan_smart,
disc_chan_valc ;
run;


*deleting outlier customer;

proc sql;
delete from x where tenure_day = 2059 and days_between_trans= 23;
run; 



*Standardize the variables;

proc standard data= x mean=0 std=1 out=stnd;
var
points_ratio
email_send
items_tot_distinct
items_tot
net_amt_p_item
checks_tot
net_sales_p_chck
net_sales_tot
days_between_trans
tenure_day
age
guests_last_12mo;
run;



* clustering;
proc fastclus data = stnd
maxclusters = 5 out = clstr ;
var
fd_cat_bev
fd_cat_brunc
fd_cat_buffe
fd_cat_combo
fd_cat_dess
fd_cat_drink
fd_cat_kids
fd_cat_other
fd_cat_side
tenure_day
disc_beverage
disc_dessert
disc_food
disc_type_comp
disc_chan_advo
disc_chan_demo
disc_chan_empl
disc_chan_gmms
disc_chan_gps
disc_chan_local
disc_chan_other
disc_chan_value
disc_pct_tot
disc_pct_trans;
run;


*Adding CLUSTER variable to the original dataset;

data temp;
set clstr (drop = age
checks_tot
days_between_trans
disc_app
disc_beverage
disc_chan_advo
disc_chan_demo
disc_chan_empl
disc_chan_gmms
disc_chan_gps
disc_chan_local
disc_chan_other
disc_chan_value
disc_dessert
disc_food
disc_other
disc_pct_tot
disc_pct_trans
disc_ribs
disc_sandwich
disc_ticket
disc_type_bogo
disc_type_comp
disc_type_dolfood
disc_type_free
disc_type_other
disc_type_pctfood
email_click_rate
email_forward_rate
email_open_rate
email_send
fd_cat_alcoh
fd_cat_app
fd_cat_bev
fd_cat_brunc
fd_cat_buffe
fd_cat_burg
fd_cat_combo
fd_cat_dess
fd_cat_drink
fd_cat_h_ent
fd_cat_kids
fd_cat_l_ent
fd_cat_other
fd_cat_side
fd_cat_soupsal
fd_cat_steak
guests_last_12mo
items_tot
items_tot_distinct
net_amt_p_item
net_sales_p_chck
net_sales_tot
points_ratio
rest_loc_Rest
rest_loc_Take_out
rest_loc_bar
rest_loc_rm_serv
tenure_day
time_breakfast
time_dinner
time_late_nite
time_lunch
DISTANCE);
run;


data proj;
merge x temp;
by customer_number;
run;

*Each cluster as a dataset;

data cluster_1;
set proj(where = (CLUSTER=1));
run;

data cluster_2;
set proj(where = (CLUSTER=2));
run;

data cluster_3;
set proj(where = (CLUSTER=3));
run;

data cluster_4;
set proj(where = (CLUSTER=4));
run;

data cluster_5;
set proj(where = (CLUSTER=5));
run;


*Price Elasticity;

*Cluster1;

proc reg data = cluster_1;
model items_tot = net_amt_p_item;
run;

proc means data = cluster_1;
var items_tot net_amt_p_item;
run;

*Cluster2;

proc reg data = cluster_2;
model items_tot = net_amt_p_item;
run;

proc means data = cluster_2;
var items_tot net_amt_p_item;
run;

*Cluster3;

proc reg data = cluster_3;
model items_tot = net_amt_p_item;
run;

proc means data = cluster_3;
var items_tot net_amt_p_item;
run;

*Cluster4;

proc reg data = cluster_4;
model items_tot = net_amt_p_item;
run;

proc means data = cluster_4;
var items_tot net_amt_p_item;
run;

*Cluster5;

proc reg data = cluster_5;
model items_tot = net_amt_p_item;
run;

proc means data = cluster_5;
var items_tot net_amt_p_item;
run;



*generating means of all variables by cluster;
data clustermeans;
set proj;
run;


proc sort data = clustermeans; by cluster; run;

proc means data = clustermeans ; by cluster; 
output out = meansC; run;


data means2;
set meansC;
where _stat_ = 'MEAN';
run;

*means2 has mean values of all variables;

proc print data = means2(drop = customer_number);
run;


*average emails sent grouped by cluster;

proc sql;
select cluster, email_send from means2;
run;

*total revenue and customer count for each cluster;

proc sql;
select sum(net_sales_tot), count(customer_number) from proj where cluster = 1;
select sum(net_sales_tot), count(customer_number) from proj where cluster = 2;
select sum(net_sales_tot), count(customer_number) from proj where cluster = 3;
select sum(net_sales_tot), count(customer_number) from proj where cluster = 4;
select sum(net_sales_tot), count(customer_number) from proj where cluster = 5;
run;


*time preference for each cluster;

proc sql;
select 
cluster,
time_breakfast,
time_dinner,
time_late_nite,
time_lunch from means2;
run;

*loyalty;
proc sql;
select cluster, tenure_day from means2;
run;

*discount;

proc sql;
select 
cluster,
disc_app,
disc_beverage,
disc_dessert,
disc_food,
disc_other,
disc_ribs,
disc_sandwich,
disc_ticket from means2;
run;

*average revenue;
proc sql;
  select cluster, 
                    mean(net_sales_tot) as average_revenue
   from proj
   group by cluster;
run;

*frequency;

proc sql;
  select cluster, 
                    mean(days_between_trans) as average_days_betwnTrans
   from proj
   group by cluster;
run;


*Anova;

proc anova data = proj;
class cluster;
model net_sales_tot = cluster;
run;

proc anova data = proj;
class cluster;
model net_sales_tot = cluster;
means cluster / SNK alpha=0.05;
run;

*email regression;

proc reg data = cluster_5;
model net_sales_tot = email_send;
run;
