//
//  CognitoConfig.swift
//  DogWearableApp
//
//  Created by Chispi on 05/02/2018.
//  Copyright © 2018 WearablesGuder. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider
import AWSCore

let CognitoIdentityUserPoolRegion: AWSRegionType = .USEast2
let CognitoIdentityUserPoolId = "us-east-2_ap5WZLSbp"
let CognitoIdentityUserPoolAppClientId = "53bsbpfq99ilmqfh4thjos482m"
let CognitoIdentityUserPoolAppClientSecret = "15u0emtr9a4mq6sne97k7rrsldpe2l3ecqdvj4l572qvat7q25nn"

let AWSCognitoUserPoolsSignInProviderKey = "UserPool"

let S3BucketName: String = "dogwearableapp-userfiles-mobilehub-2045267296"   // Update this to your bucket name
//let S3DownloadKeyName: String = "test-image.png"    // Name of file to be downloaded
//let S3UploadKeyName: String = "test-image.png"      // Name of file to be uploaded
