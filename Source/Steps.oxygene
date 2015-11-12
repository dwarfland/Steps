<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" DefaultTargets="Build" ToolsVersion="4.0">
    <PropertyGroup>
        <RootNamespace>Steps</RootNamespace>
        <ProjectGuid>{c802b246-d7e1-4e34-8673-595519830cfc}</ProjectGuid>
        <OutputType>Executable</OutputType>
        <AssemblyName>Steps</AssemblyName>
        <AllowGlobals>False</AllowGlobals>
        <AllowLegacyWith>False</AllowLegacyWith>
        <AllowLegacyOutParams>False</AllowLegacyOutParams>
        <AllowLegacyCreate>False</AllowLegacyCreate>
        <AllowUnsafeCode>False</AllowUnsafeCode>
        <Configuration Condition="'$(Configuration)' == ''">Release</Configuration>
        <SDK>iOS</SDK>
        <CreateAppBundle>True</CreateAppBundle>
        <InfoPListFile>.\Resources\Info.plist</InfoPListFile>
        <Name>Steps</Name>
        <CreateHeaderFile>False</CreateHeaderFile>
        <BundleIdentifier>com.dwarfland.steps</BundleIdentifier>
        <ProvisioningProfileName>Steps Develop 2014</ProvisioningProfileName>
        <ProvisioningProfile>93464934-b806-47ff-b2ff-203ceef23f0b</ProvisioningProfile>
        <DeploymentTargetVersion>8.0</DeploymentTargetVersion>
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
        <Optimize>false</Optimize>
        <OutputPath>.\bin\Debug</OutputPath>
        <DefineConstants>DEBUG;TRACE;</DefineConstants>
        <GenerateDebugInfo>True</GenerateDebugInfo>
        <EnableAsserts>True</EnableAsserts>
        <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
        <CaptureConsoleOutput>False</CaptureConsoleOutput>
        <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
        <CodesignCertificateName>iPhone Developer: marc hoffman (K2YTD84U6W)</CodesignCertificateName>
        <CreateIPA>True</CreateIPA>
        <Architecture>armv7;armv7s</Architecture>
        <ProvisioningProfileName>Steps Develop 2014</ProvisioningProfileName>
        <ProvisioningProfile>93464934-b806-47ff-b2ff-203ceef23f0b</ProvisioningProfile>
        <GenerateDSym>True</GenerateDSym>
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
        <Optimize>true</Optimize>
        <OutputPath>.\bin\Release</OutputPath>
        <GenerateDebugInfo>False</GenerateDebugInfo>
        <EnableAsserts>False</EnableAsserts>
        <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
        <CaptureConsoleOutput>False</CaptureConsoleOutput>
        <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
        <CreateIPA>True</CreateIPA>
        <Architecture>armv7;armv7s</Architecture>
        <CodesignCertificateName>iPhone Distribution: RemObjects Software (24G43Y5373)</CodesignCertificateName>
        <ProvisioningProfileName>Steps App Store</ProvisioningProfileName>
        <ProvisioningProfile>F0256073-C1CE-4FDC-ADBA-A015F96F7D8C</ProvisioningProfile>
        <GenerateDSym>True</GenerateDSym>
    </PropertyGroup>
    <ItemGroup>
        <Reference Include="CoreGraphics.fx"/>
        <Reference Include="CoreLocation.fx"/>
        <Reference Include="CoreMotion.fx"/>
        <Reference Include="Foundation.fx"/>
        <Reference Include="libNougat.fx">
            <HintPath>C:\Program Files (x86)\RemObjects Software\Oxygene\Nougat\Oxygene Reference Libraries\iOS\libNougat.fx</HintPath>
        </Reference>
        <Reference Include="MapKit.fx"/>
        <Reference Include="UIKit.fx"/>
        <Reference Include="rtl.fx"/>
        <Reference Include="HealthKit.fx"/>
    </ItemGroup>
    <ItemGroup>
        <Compile Include="AppDelegate.pas"/>
        <Compile Include="RootViewController.pas"/>
        <Compile Include="Program.pas"/>
        <Compile Include="StepsCellView.pas"/>
        <Compile Include="..\TwinPeaks\iOS\Oxygene\TPBaseCell.pas"/>
        <Compile Include="..\TwinPeaks\iOS\Oxygene\TPBaseCellView.pas"/>
        <AppResource Include="Resources\App Icons\App-120.png">
            <SubType>Content</SubType>
        </AppResource>
        <Content Include="Resources\Info.plist"/>
        <None Include="Resources\App Icons\App-1024.png"/>
        <AppResource Include="Resources\Launch Images\Default-568h@2x.png"/>
        <AppResource Include="StepsToday\bin\$(Configuration)\iOS\StepsToday.appex">
            <DestinationFolder>Contents/PlugIns</DestinationFolder>
        </AppResource>
        <Storyboard Include="Resources\Launch.storyboard"/>
        <AppResource Include="Resources\App Icons\App-180.png"/>
    </ItemGroup>
    <ItemGroup>
        <Folder Include="Properties\"/>
        <Folder Include="Resources\"/>
        <Folder Include="Resources\App Icons\"/>
        <Folder Include="Resources\Launch Images\"/>
    </ItemGroup>
    <Import Project="$(MSBuildExtensionsPath)\RemObjects Software\Oxygene\RemObjects.Oxygene.Nougat.targets"/>
    <PropertyGroup>
        <PreBuildEvent/>
    </PropertyGroup>
</Project>