/**
 * Created by dawid on 18.04.2023.
 */

import {api, track, LightningElement} from 'lwc';
import getBureauInfo from '@salesforce/apex/Capitec_BureauInformationViewController.getBureauInfo'

export default class CapitecBureauInformationView extends LightningElement {
    @api recordId;
    @api jsonRaw
    @api messageError;

    @track dataLoaded = false;

    renderedCallback() {
        let mainContainer = this.template.querySelector('[data-id="main-container"]');
        let spinner = this.template.querySelector('[data-id="spinner"]');

        if(this.dataLoaded === true){
            console.log('returning');
            return
        }
        try{
            getBureauInfo({accountId: this.recordId}).then(result =>{
                // mainContainer.innerHTML = JSON.stringify(result);
                console.log(result.statusCode);
                if(result.statusCode !== 200){
                    console.log('handling error');
                    let errorMessage = this.template.querySelector('[data-id="error-message"]');
                    let mainContainer = this.template.querySelector('[data-id="main-container"]');

                    errorMessage.removeAttribute('hidden');
                    mainContainer.setAttribute('hidden', 'hidden');
                    spinner.setAttribute('hidden', 'hidden');
                    this.messageError = result.responseMessage;
                    this.dataLoaded = true;
                    return;
                }
                console.log('proceeding with data');
                this.composeDefiniteMatchTable(result.bureauResultModel.bureauResponse.returnData.bureauMatch);
                this.composeEmployersTable(result.bureauResultModel.bureauResponse.returnData.employers)
                this.composeAddressesTable(result.bureauResultModel.bureauResponse.returnData.addresses)
                this.composeContactTable(result.bureauResultModel.bureauResponse.returnData.telephones)
                this.composePropertyTable(result.bureauResultModel.bureauResponse.returnData.deeds)
                this.composePrincipalInfoTable(result.bureauResultModel.bureauResponse.returnData.directors);

                this.jsonRaw = JSON.stringify(result, null, "\t");
                spinner.setAttribute('hidden', 'hidden');
                this.dataLoaded = true;
            })

        }
        catch (error){
            console.log(error.message);
            spinner.setAttribute('hidden', 'hidden');
            this.dataLoaded = true;
        }



    }

    toggleJSON(){
        let jsonBody = this.template.querySelector('[data-id="json-body"]');
        if(jsonBody.hasAttribute('hidden')){
            jsonBody.removeAttribute('hidden');
        }
        else{
            jsonBody.setAttribute('hidden','hidden');
        }
    }


    composeDefiniteMatchTable(bureauMatch){
        if(typeof  bureauMatch === 'undefined'){
            return
        }
        let matchTable = this.template.querySelector('[data-id="definite-match-table"]');
        let newTR = document.createElement('tr');

        let identificationTD = document.createElement('td');
        let nameTD = document.createElement('td');
        let surnameTD = document.createElement('td');
        let identificationStatusTD = document.createElement('td');
        let deceasedDateTD = document.createElement('td');
        let countryTD = document.createElement('td');


        identificationTD.innerHTML = bureauMatch.identityNumber;
        nameTD.innerHTML = bureauMatch.firstName;
        surnameTD.innerHTML = bureauMatch.surname;
        identificationStatusTD.innerHTML = bureauMatch.statusCode;
        deceasedDateTD.innerHTML = bureauMatch.deceasedDate;
        countryTD.innerHTML = bureauMatch.countryName;

        newTR.appendChild(identificationTD);
        newTR.appendChild(nameTD);
        newTR.appendChild(surnameTD);
        newTR.appendChild(identificationStatusTD);
        newTR.appendChild(deceasedDateTD);
        newTR.appendChild(countryTD);

        matchTable.appendChild(newTR);

    }

    composeEmployersTable(employers){

        let employersTable = this.template.querySelector('[data-id="employers-table"]');

        if(typeof employers !== 'undefined'){
            employers.forEach(employer =>{

                let newTR = document.createElement('tr');
                let name = document.createElement('td');
                let occupation = document.createElement('td');
                let type = document.createElement('td');
                let salaryFreq = document.createElement('td');
                let payslip = document.createElement('td');
                let employeeNo = document.createElement('td');
                let activeDate = document.createElement('td');

                name.innerHTML = employer.employerName;
                occupation.innerHTML = employer.occupation;
                type.innerHTML = '- not mapped -';
                salaryFreq.innerHTML = '- not mapped -';
                payslip.innerHTML = '- not mapped -';
                employeeNo.innerHTML = '- not mapped -';
                activeDate.innerHTML = employer.employmentDate;

                newTR.appendChild(name);
                newTR.appendChild(occupation);
                newTR.appendChild(type);
                newTR.appendChild(salaryFreq);
                newTR.appendChild(payslip);
                newTR.appendChild(employeeNo);
                newTR.appendChild(activeDate);


                employersTable.appendChild(newTR);
            })
        }
    }


    composeAddressesTable(addresses){
        if(typeof  addresses === 'undefined'){
            return
        }
        let addressesTable = this.template.querySelector('[data-id="addresses-table"]');

        addresses.forEach(address =>{
            let newTR = document.createElement('tr');

            let type = document.createElement('td');
            let addressVal = document.createElement('td');
            let postal = document.createElement('td');
            let dateLastUpdated = document.createElement('td');


            type.innerHTML = address.addressTypeCodeDesc;
            addressVal.innerHTML = (address.line1 + '\n' + address.line2 + '\n' + address.line3 + '\n' + address.line4) ;
            postal.innerHTML = address.postalCode;
            dateLastUpdated.innerHTML = address.dateLastUpdated;

            newTR.appendChild(type);
            newTR.appendChild(addressVal);
            newTR.appendChild(postal);
            newTR.appendChild(dateLastUpdated);

            addressesTable.appendChild(newTR);
        });
    }

    composeContactTable(telephones){
        if(typeof  telephones === 'undefined'){
            return
        }
        let contactTable = this.template.querySelector('[data-id="contact-numbers-table"]');

        telephones.forEach(telephone =>{
            let newTR = document.createElement('tr');

            let type = document.createElement('td');
            let contactNo = document.createElement('td');
            let dateCreated = document.createElement('td');


            type.innerHTML = telephone.telephoneTypeDesc;
            contactNo.innerHTML = telephone.telephoneNumber;
            dateCreated.innerHTML = telephone.dateFirstCreated;

            newTR.appendChild(type);
            newTR.appendChild(contactNo);
            newTR.appendChild(dateCreated);

            contactTable.appendChild(newTR);
        });
    }

    composePropertyTable(deeds){

        let contactTable = this.template.querySelector('[data-id="properties-owned-table"]');

        if(typeof  deeds === 'undefined'){
            let newTR = document.createElement('tr');

            let erfNo = document.createElement('td');
            let type = document.createElement('td');
            let townDivision = document.createElement('td');
            let purchaseAmount = document.createElement('td');
            let regDate = document.createElement('td');
            let purchaseDate = document.createElement('td');


            erfNo.innerHTML = '---';
            type.innerHTML = '---'
            townDivision.innerHTML = '---'
            purchaseAmount.innerHTML = '---'
            regDate.innerHTML = '---'
            purchaseDate.innerHTML = '---'

            newTR.appendChild(erfNo);
            newTR.appendChild(type);
            newTR.appendChild(townDivision);
            newTR.appendChild(purchaseAmount);
            newTR.appendChild(regDate);
            newTR.appendChild(purchaseDate);

            contactTable.appendChild(newTR);
        }
        else{
            deeds.forEach(deed =>{
                deed.propertyDetails.forEach(property =>{
                    let newTR = document.createElement('tr');

                    let erfNo = document.createElement('td');
                    let type = document.createElement('td');
                    let townDivision = document.createElement('td');
                    let purchaseAmount = document.createElement('td');
                    let regDate = document.createElement('td');
                    let purchaseDate = document.createElement('td');


                    erfNo.innerHTML = deed.erfNo;
                    type.innerHTML = deed.propertyTypeCodeDesc;
                    townDivision.innerHTML = deed.township;
                    purchaseAmount.innerHTML = property.purchasePrice;
                    regDate.innerHTML = property.registrationDate;
                    purchaseDate.innerHTML = property.purchaseDate;

                    newTR.appendChild(erfNo);
                    newTR.appendChild(type);
                    newTR.appendChild(townDivision);
                    newTR.appendChild(purchaseAmount);
                    newTR.appendChild(regDate);
                    newTR.appendChild(purchaseDate);

                    contactTable.appendChild(newTR);
                });

            });
        }
    }


    composePrincipalInfoTable(principalInfo){
        let contactTable = this.template.querySelector('[data-id="principal-info-owned-table"]');

        if(typeof principalInfo !== 'undefined'){
            principalInfo.forEach(director =>{
                let newTR = document.createElement('tr');
                let companyName = document.createElement('td');
                let type = document.createElement('td');
                let status = document.createElement('td');
                let registrationNo = document.createElement('td');
                let regDate = document.createElement('td');


                companyName.innerHTML = director.companyName;
                type.innerHTML = director.entTypeCodeDesc;
                status.innerHTML = director.statusCodeDesc;
                registrationNo.innerHTML = director.companyRegNumber;
                regDate.innerHTML = director.registrationDate;

                newTR.appendChild(companyName);
                newTR.appendChild(type);
                newTR.appendChild(status);
                newTR.appendChild(registrationNo);
                newTR.appendChild(regDate);

                contactTable.appendChild(newTR);
            });
        }
    }


    downloadCSVFile(event) {
        console.log('teste file');

        let DetailSets = this.DetailSets;
        let data = [];
        let headerArray = [];
        let csvContentArray = [];


        //Fill out the Header of CSV
        //headerArray.push(' ');
        let regExpr = /[&\/\\#°]/g;
        let delivery = Delivery;
        let deliveryCnt = delivery.replace(regExpr, ".");
        headerArray.push(Cnt);
        headerArray.push(date);
        headerArray.push(Amount);
        data.push(headerArray.join("\t"));

        for (let i = 0; i < DetailSets.length; i++) {
            let tempArray = [];
            tempArray.push(DetailSets[i].Vbln__c);
            tempArray.push(DetailSets[i].Eat__c);
            tempArray.push(DetailSets[i].Amt__c);
            //console.log("tempArray.join() : " + tempArray.join("\t"));
            data.push(tempArray.join("\t"));
        }

        let dataString = data.join("\n");

        let csvContent = dataString;


        let Name = this.Name;
        let fileName = "Export " + Name;

        fileName = fileName.replace(/ /g, "_");
        fileName += ".xls";
        let uri = 'data:text/xls;charset=utf-8,' + encodeURIComponent(csvContent);

        if (navigator.msSaveBlob) { // IE 10+
            let blob = new Blob([csvContent], { type: "text/xls;charset=utf-8;" });
            navigator.msSaveBlob(blob, fileName);
        }
        else {

            let link = document.createElement("a");


            link.setAttribute('download', fileName);
            link.href = uri;


            link.style = "visibility:hidden";

            link.click();

        }
    }

}