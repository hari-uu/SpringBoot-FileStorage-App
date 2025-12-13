# 🚀 Quick Fix: Jenkins Credential Setup

## ❌ Current Error
```
ERROR: aws-account-id
```

This means Jenkins cannot find the credential with ID `aws-account-id`.

---

## ✅ **SOLUTION: Add AWS Account ID Credential**

### **Step-by-Step:**

1. **Open Jenkins Dashboard**
   - Go to: `http://localhost:8080` (or your Jenkins URL)

2. **Navigate to Credentials**
   - Click: **Manage Jenkins**
   - Click: **Credentials**
   - Click: **(global)** domain
   - Click: **Add Credentials** (on the left)

3. **Add AWS Account ID**
   - **Kind:** Select `Secret text`
   - **Scope:** `Global (Jenkins, nodes, items, all child items, etc)`
   - **Secret:** Enter your AWS Account ID (e.g., `123456789012`)
   - **ID:** `aws-account-id` (MUST BE EXACT)
   - **Description:** `AWS Account ID for ECR/ECS`
   - Click **Create**

4. **Add AWS Credentials (for ECR/ECS access)**
   - Click **Add Credentials** again
   - **Kind:** Select `AWS Credentials`
   - **Scope:** `Global`
   - **ID:** `aws-credentials` (MUST BE EXACT)
   - **Access Key ID:** Your AWS Access Key
   - **Secret Access Key:** Your AWS Secret Key
   - **Description:** `AWS Credentials for ECR and ECS`
   - Click **Create**

---

## 🎯 **How to Get Your AWS Account ID**

### **Option 1: AWS Console**
1. Log into AWS Console
2. Click on your username (top right)
3. Your Account ID is shown in the dropdown

### **Option 2: AWS CLI**
```bash
aws sts get-caller-identity --query Account --output text
```

### **Option 3: If you don't have AWS yet**
You can use the **local testing Jenkinsfile** instead:
- Rename `Jenkinsfile` to `Jenkinsfile.aws`
- Rename `Jenkinsfile.local` to `Jenkinsfile`
- This version doesn't require AWS credentials

---

## 🔄 **After Adding Credentials**

1. Go back to your Jenkins job
2. Click **"Build Now"**
3. The pipeline should now proceed past the credential error

---

## 📊 **Expected Pipeline Flow**

After fixing credentials, the pipeline will:
1. ✅ Validate Prerequisites (Maven, Java, Docker)
2. ✅ Checkout code from GitHub
3. ✅ Build JAR with Maven
4. ✅ Run tests
5. ✅ Build Docker image
6. ⚠️ Push to ECR (requires AWS setup)
7. ⚠️ Deploy to ECS (requires AWS setup)

---

## 🧪 **For Local Testing (Without AWS)**

If you want to test Jenkins without AWS:

1. **Rename files:**
   ```bash
   mv Jenkinsfile Jenkinsfile.aws
   mv Jenkinsfile.local Jenkinsfile
   git add .
   git commit -m "test: use local Jenkinsfile without AWS"
   git push origin main
   ```

2. **Trigger Jenkins build**

3. **This will:**
   - Build your application
   - Run tests
   - Create Docker image locally
   - Skip AWS deployment

---

## 🔍 **Verify Credentials Were Added**

After adding credentials, verify:

1. Go to: **Manage Jenkins → Credentials → (global)**
2. You should see:
   - ✅ `aws-account-id` (Secret text)
   - ✅ `aws-credentials` (AWS Credentials)

---

## ⚠️ **Common Mistakes**

❌ **Wrong ID:** Using `aws_account_id` instead of `aws-account-id`
❌ **Wrong Kind:** Using "Username with password" instead of "Secret text"
❌ **Wrong Scope:** Using "System" instead of "Global"

✅ **Correct:** Exactly as shown in Step 3 above

---

## 🎉 **Next Steps After Fixing**

Once credentials are added:
1. Build will proceed further
2. You may encounter AWS resource errors (ECR, ECS)
3. Follow the `CICD_SETUP_GUIDE.md` to set up AWS resources
4. Or use `Jenkinsfile.local` for testing without AWS

---

## 📞 **Still Having Issues?**

Check the Jenkins console output for:
- ✅ "Checking required tools..." - Prerequisites passed
- ✅ "Checking out Revision..." - Git checkout worked
- ✅ "Building JAR..." - Maven build started
- ❌ Any error messages about missing tools or permissions
