
## 🔍 Check version
```
sage -v
```

---

## 🔄 Update (2–3× per year)

1. Go to:
   https://github.com/3-manifolds/Sage_macOS/releases

2. Download latest arm64 .dmg

3. Install:
   - Drag .app → /Applications
   - Run included .pkg installer

---

## ✅ Verify after update
```
sage -v
jupyter kernelspec list
```

Expect:
- SageMath 10.x
- sagemath-10.x kernel present

---

## 🧪 Quick functionality test
```
sage -c "print(factor(x^4 - 1))"
```

---

## 🧼 Clean old kernel (if needed)
```
sudo jupyter kernelspec remove sagemath-OLD
```

---

## 🧠 Notes
- Sage is not Conda-managed
- Installed via:
  - /Applications/SageMath-*.app
  - /usr/local/bin/sage
  - /usr/local/share/jupyter/kernels/
- .pkg step is required for CLI + Jupyter integration
