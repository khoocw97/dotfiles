#!/usr/bin/env python3
"""双面手动翻纸打印助手。

每4页一组：前2页归A面，后2页归B面，A4横向一面两页（number-up=2）。
脚本把 A/B 面各抽成一个临时 PDF 整份直发，内容流不动（扫描件安全）。

实测教训，勿回退：
  - 页码不能用 lp -P 选：pdftopdf 先拼张再选张，-P 1-2,5-6 会打出 1,2,3,4。
  - 不能加 -o landscape：number-up=2 已自动横向左右排，再转就变直向上下摞。
  - 不能加 page-* 边距：多余选项会在 Gutenprint 上把纸打白。

用法：
  python3 duplex_print.py 文件.pdf
  python3 duplex_print.py 文件.pdf --dry-run        # 只显示分组，不打印
  python3 duplex_print.py 文件.pdf -d Canon_E410_series
"""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

LP_NUP = [
    "-o", "media=A4",
    "-o", "number-up=2",
    "-o", "number-up-layout=lrtb",
    "-o", "fit-to-page",
]


def split_pages(n: int):
    a, b = [], []
    for i in range(1, n + 1):
        if i % 4 in (1, 2):
            a.append(i)
        else:
            b.append(i)
    return a, b


def compress(pages: list[int]) -> str:
    if not pages:
        return ""
    ranges = []
    start = prev = pages[0]
    for p in pages[1:]:
        if p == prev + 1:
            prev = p
        else:
            ranges.append(f"{start}-{prev}" if start != prev else f"{start}")
            start = prev = p
    ranges.append(f"{start}-{prev}" if start != prev else f"{start}")
    return ",".join(ranges)


def make_face_file(reader, pages: list[int], out_path: Path):
    # 只按页复制，内容流不动；/Annots 坏注释会让 pdftopdf 失败停机，顺手删掉
    from pypdf import PdfWriter

    writer = PdfWriter()
    for pageno in pages:
        p = reader.pages[pageno - 1]
        if "/Annots" in p:
            del p["/Annots"]
        writer.add_page(p)
    try:
        if "/AcroForm" in writer._root_object:
            del writer._root_object["/AcroForm"]
    except Exception:
        pass
    with open(out_path, "wb") as f:
        writer.write(f)


def run_lp_file(pdf_file: Path, printer: str | None) -> int:
    cmd = ["lp"]
    if printer:
        cmd += ["-d", printer]
    cmd += LP_NUP + [str(pdf_file)]
    print(f"$ {' '.join(cmd)}")
    r = subprocess.run(cmd, capture_output=True, text=True)
    print(r.stdout.strip())
    if r.returncode != 0:
        print(r.stderr.strip(), file=sys.stderr)
    return r.returncode


def main():
    ap = argparse.ArgumentParser(description="双面翻纸打印：A面/B面分组，CUPS拼版，一面两页")
    ap.add_argument("pdf", nargs="?", default=None, help="PDF 文件路径（不给则运行时询问）")
    ap.add_argument("-d", "--printer", default=None, help="打印机名（默认系统默认打印机）")
    ap.add_argument("--dry-run", action="store_true", help="只显示分组，不实际打印")
    ap.add_argument("--yes", action="store_true", help="全程不询问（A->B、下一份都自动继续）")
    ap.add_argument("--keep", action="store_true", help="保留 /tmp 下的抽页临时文件（默认打完删除）")
    args = ap.parse_args()

    pdf_arg = args.pdf
    if not pdf_arg:
        pdf_arg = input("请输入 PDF 路径（可直接把文件拖进终端）：").strip().strip("'\"")
        if not pdf_arg:
            print("未输入文件路径，已退出。", file=sys.stderr)
            sys.exit(1)
    pdf = Path(pdf_arg).expanduser().resolve()
    if not pdf.is_file():
        print(f"找不到文件：{pdf}", file=sys.stderr)
        sys.exit(1)

    try:
        from pypdf import PdfReader
        reader = PdfReader(str(pdf))
        if reader.is_encrypted:
            reader.decrypt("")
        n = len(reader.pages)
    except Exception as e:
        msg = str(e)
        if "cryptography" in msg or "AES" in msg:
            print(f"读取 PDF 失败：{e}", file=sys.stderr)
            print("缺 cryptography 库（AES 加密的 PDF 需要，新系统常见）。装一次即可：", file=sys.stderr)
            print("  python3 -m pip install --user 'cryptography>=3.1'", file=sys.stderr)
            print("或系统包：sudo dnf install python3-cryptography", file=sys.stderr)
        else:
            print(f"读取 PDF 失败：{e}", file=sys.stderr)
        sys.exit(1)
    if n == 0:
        print("PDF 页数为 0，无需打印。")
        sys.exit(0)

    a, b = split_pages(n)
    ra, rb = compress(a), compress(b)
    # number-up 会自动把落单的半张补白，不用手动对齐
    sheets = max((len(a) + 1) // 2, (len(b) + 1) // 2)

    print(f"文件：{pdf}\n总页数：{n}，A4横向一面两版，最少需要 {sheets} 张纸")
    print(f"A面原稿（{len(a)}页）：{ra}")
    print(f"B面原稿（{len(b)}页）：{rb}")

    if args.dry_run:
        print("[dry-run] 未打印。去掉 --dry-run 即真实打印。")
        return

    tmpdir = Path(tempfile.mkdtemp(prefix="duplex_"))
    a_file = tmpdir / f"{pdf.stem}_A面.pdf"
    b_file = tmpdir / f"{pdf.stem}_B面.pdf"
    make_face_file(reader, a, a_file)
    make_face_file(reader, b, b_file)

    if not args.yes:
        ans = input(f"最少需要 {sheets} 张 A4 纸（横向），是否开始打印 A 面？回车开始，输入 n 取消：").strip().lower()
        if ans in ("n", "no", "q", "quit"):
            print("已取消打印。")
            return

    try:
        copy_no = 1
        while True:
            print(f"\n===== 第 {copy_no} 份 =====")
            print(f"[1/2] 正在打印 A 面（{ra}）…")
            if run_lp_file(a_file, args.printer) != 0:
                print("A 面发送失败，已中止。", file=sys.stderr)
                sys.exit(1)

            if not args.yes:
                print("\nA 面已发送。请等 A 面打完，取出纸翻面放回（整叠一起翻）。")
                ans = input("回车继续打印 B 面，输入 n 取消本份：").strip().lower()
                if ans in ("n", "no", "q", "quit"):
                    print("已取消本份的 B 面。")
                    break

            print(f"\n[2/2] 正在打印 B 面（{rb}）…")
            if run_lp_file(b_file, args.printer) != 0:
                print("B 面发送失败。", file=sys.stderr)
                sys.exit(1)
            print(f"第 {copy_no} 份完成：A/B 面任务均已发送。")

            if args.yes:
                break
            ans = input("是否再打印多一份？回车继续，输入 n 结束：").strip().lower()
            if ans in ("n", "no", "q", "quit"):
                print(f"共打印了 {copy_no} 份，结束。")
                break
            copy_no += 1
    finally:
        if not args.keep:
            for f in (a_file, b_file):
                try:
                    f.unlink()
                except OSError:
                    pass
            try:
                tmpdir.rmdir()
            except OSError:
                pass
        else:
            print(f"抽页文件已保留在：{tmpdir}")


if __name__ == "__main__":
    main()
