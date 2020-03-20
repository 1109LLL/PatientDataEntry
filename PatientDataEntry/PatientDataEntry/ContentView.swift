//
//  ContentView.swift
//  PatientDataEntry
//
//  Created by Yingming Luo on 03/03/2020.
//  Copyright © 2020 GOSH-FHIRworks2020. All rights reserved.
//

import SwiftUI
import Combine

private var access_token: String = "No valid token"
private var validPatient: Bool = false
var patientInfo: String = ""

struct ContentView: View
{

    
    @State var expand = false
    @State var access_token: String = "Cannot acquire access token"
    @State private var showValidAlert: Bool = false
    @State private var showInvalidAlert: Bool = false
    @State var showHeartRateType: Bool = false
    @State var showBloodPressureType: Bool = false
    @State var patientName: String = ""
    @State var patientID: String = ""
    @State var heartRate: String = ""
    @State var heartrate: Double = 0.0
    @State var systolic: String = ""
    @State var diastolic: String = ""
    @State var showAlert: Bool = false
    @State var showBloodPressurePostAlert: Bool = false
    @State var showHeartRatePostAlert: Bool = false
    @State var value : CGFloat = 0
    
    var body: some View
    {
        
        VStack(alignment: .leading)
        {
            VStack(alignment: .leading)
            {
                Text("Patient name")
                    .font(.headline)
                TextField("Enter patient's name", text: $patientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Patient ID")
                    .font(.headline)
                
                HStack
                {
                    TextField("Enter patient's ID", text: $patientID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        getAccessToken()
                        self.showAlert = true
                    }){
                        HStack
                        {
                            Image(systemName: "pencil")
                            Text("Verify")
                                .font(.body)
                        }
                    }
                    .buttonStyle(GradientButtonStyle())
                    .alert(isPresented: $showAlert)
                    {
                        verifyPatient(patientID: patientID)
                        if validPatient
                        {
                            validPatient = false
                            return Alert(title: Text("Patient Verification"), message: Text("Patient ID is valid"),
                            dismissButton: .default(Text("OK")))
                        }
                        else
                        {
                            return Alert(title: Text("Patient Verification"), message: Text("Patient ID is invalid \nplease check patient ID"), dismissButton: .default(Text("OK")))
                        }
                    }
                }
                
                Text("Select Type")
                    .font(.headline)
                
                Toggle(isOn: $showBloodPressureType)
                {
                    Text("Blood pressure")
                }
                
                if showBloodPressureType
                {
                    ScrollView
                    {
                        VStack(alignment: .leading)
                        {
                            Text("Patient systolic reading")
                                
                            TextField("Enter patient's systolic reading", text: $systolic)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onReceive(Just(systolic)) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        self.systolic = filtered
                                    }
                                }
                            
                            Text("Patient diastolic reading")

                            TextField("Enter patient's diastolic reading", text: $diastolic)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onReceive(Just(diastolic)) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        self.diastolic = filtered
                                    }
                                }
                        }
                        .padding()
                    }
                    .frame(height:170)
                }
                
                Toggle(isOn: $showHeartRateType)
                {
                    Text("Heart Rate")
                }

                if showHeartRateType
                {
                    ScrollView
                    {
                        Text("Patient Heart Rate")
                        
                        TextField("Enter patient's heart rate reading", text: $heartRate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .frame(height: 180)
                }
            }
            .offset(y: -self.value)
            .onAppear
            {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (noti) in

                    if self.showBloodPressureType && self.showHeartRateType
                    {
                        self.value = 55
                    }
                }

                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (noti) in
                    self.value = 0
                }
            }
            
            Spacer()
            Spacer()
            
            HStack
            {
                Button(action: {
                    let systolicInt = (self.systolic as NSString).integerValue
                    let diastolicInt = (self.diastolic as NSString).integerValue
                    
                    postBloodPressure(patientID: self.patientID, systolic: systolicInt, diastolic: diastolicInt)
                    self.showBloodPressurePostAlert = true
                }){
                    Text("Post Blood pressure")
                }
                .alert(isPresented: $showBloodPressurePostAlert)
                {
                    if validPatient
                    {
                        return Alert(title: Text("Patient blood pressure"), message: Text("Successfully posted"),
                        dismissButton: .default(Text("Done")))
                    }
                    else
                    {
                        return Alert(title: Text("Patient blood pressure"), message: Text("Please verify patient"),
                        dismissButton: .default(Text("OK")))
                    }
                }
                .cornerRadius(15.0)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                
                Spacer()
                
                Button(action: {
                    postHeartRate(patientID: self.patientID, heartRate: self.heartRate)
                    self.showHeartRatePostAlert = true
                }){
                    Text("Post Heart Rate")
                }
                .alert(isPresented: $showHeartRatePostAlert)
                {
                    if validPatient
                    {
                        return Alert(title: Text("Patient heart rate"), message: Text("Successfully posted"),
                        dismissButton: .default(Text("Done")))
                    }
                    else
                    {
                        return Alert(title: Text("Patient heart rate"), message: Text("Please verify patient"),
                        dismissButton: .default(Text("OK")))
                    }
                    
                }
                .cornerRadius(15.0)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
            }
            .padding()
            .frame(width: 350, height: 30)
        }
    }
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(15.0)
            .scaleEffect(configuration.isPressed ? 1.3 : 1.0)
    }
}

func getAccessToken()
{
    let url = URL(string: "")!
    
    let payload = "".data(using: .utf8)
    
    var request = URLRequest(url: url)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    request.httpBody = payload
    
    let task = URLSession.shared.dataTask(with: request)
    { (data, response, error) in
        
        guard let data = data, error == nil else{
            print(error?.localizedDescription ?? "No data")
            return
        }

        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        if let responseJson = responseJSON as? [String: Any]{
            access_token = (responseJson["access_token"]! as AnyObject).description
            return
        }
    }
    
    task.resume()
}


func verifyPatient(patientID: String)
{
    let header: [String: String] = [

        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    let url = URL(string: "")!
    
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = header


    let task = URLSession.shared.dataTask(with: request)
    { (data, response, error) in

        guard let data = data, error == nil else{
            print(error?.localizedDescription ?? "No data")
            return
        }
//         Read HTTP Response Status code
        if let response = response as? HTTPURLResponse {
            print("Response HTTP Status code: \(response.statusCode)")
            if response.statusCode == 200 && patientID != ""
            {
                validPatient = true
            }
        }
        
    }

    task.resume()
}

func postBloodPressure(patientID: String, systolic: Int, diastolic: Int)
{
    let server_url = URL(string: "")!
    
    let time = Date()
    let timeFormatter1 = DateFormatter()
    timeFormatter1.dateFormat = "yyyy-MM-dd"
    let yyyy_mm_dd = timeFormatter1.string(from: time)
    
    let timeFormatter2 = DateFormatter()
    timeFormatter2.dateFormat = "HH:mm:ss"
    let HH_mm_ss = timeFormatter2.string(from: time)
    let ID = ""
    
    let jsonObject: [Any] = [
        [
            "string": ""
        ]
    ]
    
    let payload = try! JSONSerialization.data(withJSONObject: jsonObject)
    
    
    let header: [String: String] = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    var request = URLRequest(url: server_url)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = header
//    request.httpBody = components.query?.data(using: .utf8)
    request.httpBody = payload
    
    let task = URLSession.shared.dataTask(with: request)
    { (data, response, error) in
        
        guard let data = data, error == nil else{
                    print(error?.localizedDescription ?? "No data")
                    return
                }
        //         Read HTTP Response Status code
        if let response = response as? HTTPURLResponse {
            print("Response post HTTP Status code: \(response.statusCode)")
        }

        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        print(responseJSON)
        if let responseJson = responseJSON as? [String: Any]{
            print(responseJson)
            return
        }
    }
    
    task.resume()
    
}


func postHeartRate(patientID: String, heartRate: String)
{
    let server_url = URL(string: "")!
    
    let time = Date()
    let timeFormatter1 = DateFormatter()
    timeFormatter1.dateFormat = "yyyy-MM-dd"
    let yyyy_mm_dd = timeFormatter1.string(from: time)
    
    let timeFormatter2 = DateFormatter()
    timeFormatter2.dateFormat = "HH:mm:ss"
    let HH_mm_ss = timeFormatter2.string(from: time)
    
    
    let jsonObject: [Any] = [
        [
            "string": ""
        ]
    ]
    
    let payload = try! JSONSerialization.data(withJSONObject: jsonObject)
    
    var request = URLRequest(url: server_url)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    request.httpBody = payload
    
    let task = URLSession.shared.dataTask(with: request)
    { (data, response, error) in
        
        guard let data = data, error == nil else{
                    print(error?.localizedDescription ?? "No data")
                    return
                }

        if let response = response as? HTTPURLResponse {
            print("Response post HTTP Status code: \(response.statusCode)")
        }

        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        if let responseJson = responseJSON as? [String: Any]{
            print(responseJson)
            return
        }
    }
    
    task.resume()
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
