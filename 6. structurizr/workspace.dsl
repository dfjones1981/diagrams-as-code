workspace {

    model {
        example = softwareSystem "example" {
            aad = container "Azure Active Directory" "a" "b"
            internet = container "Internet"
            dns = container "Azure DNS"

            resourceGroup = group "Resource Group" {
                frontDoor = container "Azure Front Door"
                webApp = container "Web App" {
                    usersApi = component "User API"
                    accountsApi = component "Account API"
                    administratorUI = component "Admin UI"
                }
                cache = container "Redis Cache"
                sql = container "Azure SQL Database"

                cdn = container "Azure CDN"
                blob = container "Blob Storage"
            }
        }

        internet -> aad "Authentication"
        internet -> dns
        internet -> frontDoor
        internet -> cdn
        blob -> cdn
        frontDoor -> administratorUI
        administratorUI -> usersApi
        administratorUI -> accountsApi
        cache -> usersApi
        cache -> accountsApi
        sql -> cache

        
    }

    views {
        

        container example "Containers" {
            include *
            autoLayout
        }

        component webApp "Components" {
            include *
            autoLayout
        }

        theme default
    }

}