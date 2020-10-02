* 14.33 paper 1 code
* Catherine Huang
* 10/1/2020

* set up logfile
capture log close
log using 1433paper1.log, replace

* load data
clear
cd "/Users/chuang/Desktop/CurrentPsets/1433shortproject"  
insheet using "cleaned_OI_state_data.csv", clear

keep state_abbrev date close_nonessential_bus begin_reopen begin_shelter_in_place gps_* merchants_* governor_party spend_all new_death_rate

* generate and label control dummies
gen sheltering = (date >= begin_shelter_in_place)
gen businesses_closed = (date >= close_nonessential & date < begin_reopen)
replace governor_party = "State Has Republican Governor=1" if (governor_party == "Republican")
encode governor_party, gen(Republican)

* merge in CompTIA data
preserve
insheet using "cyberstates_data.csv", clear
tempfile cyberstates_data
save `cyberstates_data', replace
restore
merge m:1 state_abbrev using `cyberstates_data', keep(match) nogen

* label remaining variables
label variable gps_workplaces "Reduction in Workplace Hours (Percent)"
label variable sheltering "Sheltering-in-Place"
label variable businesses_closed "Nonessential Businesses Closed"
label variable tech_share "Tech Share (Percent)"

* main results
local groups "all inchigh incmiddle inclow"
foreach group in `groups' {
	ivregress 2sls merchants_`group' i.sheltering i.businesses_closed i.Republican (gps_workplaces = tech_share), robust
	eststo `group'
}
		
esttab all inchigh incmiddle inclow ///
		using "main_reg.tex", ///
		cells(b(star fmt(3)) se(par fmt(2))) margin delim("&") ///
		style(tex) eqlabels(none) collabels(, none) mlabels(none) ///
		stats(N r2, labels("N" "R-squared") fmt(0 2)) starlevels( * 0.10 ** 0.05 *** 0.010) replace ///
		prehead("\begin{threeparttable} \begin{tabular}{lcccc} \hline & \multicolumn{4}{c}{Small Business ZIP Code Income Level} \\ \hline" ) ///
		posthead("& All & High & Middle & Low \\ \hline") ///
		postfoot("\hline \end{tabular} \begin{tablenotes} \item Notes: Standard errors in parentheses below each estimate. Significance at the 1, 5, and 10 percent levels indicated by ***, **, and *, respectively. \end{tablenotes} \end{threeparttable}") ///
		legend label nonumber nobase

* instrument correlations
reg gps_workplaces tech_share
eststo techshareremote

reg Republican tech_share
eststo techsharerepub

reg sheltering tech_share
eststo techshareshelter

reg businesses_closed tech_share
eststo techsharebus

esttab techshareremote techsharerepub techshareshelter techsharebus  ///
		using "instrument.tex", ///
		cells(b(star fmt(3)) se(par fmt(2))) margin delim("&") ///
		style(tex) eqlabels(none) collabels(, none) mlabels(none) ///
		stats(N r2, labels("N" "R-squared") fmt(0 2)) starlevels( * 0.10 ** 0.05 *** 0.010) replace ///
		prehead("\begin{threeparttable} \begin{tabular}{lcccc}" \hline) ///
		posthead("& \% Change Work Volume & Republican Governor & Sheltering & Businesses Closed \\ \hline") ///
		postfoot("\hline \end{tabular} \begin{tablenotes} \item Notes: Standard errors in parentheses below each estimate. Significance at the 1, 5, and 10 percent levels indicated by ***, **, and *, respectively. \end{tablenotes} \end{threeparttable}") ///
		legend label nonumber nobase
		
* generate graphs
keep if date == "15apr2020"
set scheme s1mono
twoway (scatter gps_workplaces tech_share) (lfit gps_workplaces tech_share), legend(off) ytitle("Change in Workplace Hours (Percent)")
graph export techshareremote.png, replace


log close
