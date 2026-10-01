#!/usr/bin/env python3
"""双面手动翻纸打印助手（A4 横向拼版版）。

规则：每4页一组，前2页归A面，后2页归B面。
拼版：A4 横向（842x595pt），一面并排塞 2 个原页。
  N=19 -> A面原稿 1,2,5,6,9,10,13,14,17,18
          拼成 5 张：[1|2] [5|6] [9|10] [13|14] [17|18]
          B面原稿 3,4,7,8,11,12,15,16,19
          拼成 5 张：[3|4] [7|8] [11|12] [15|16] [19|空]
  N=10 -> A面 3 张：[1|2] [5|6] [9|10]；B面 3 张：[3|4] [7|8] [空|空]
          （B面补空白页对齐，保证翻纸不错位）
打印时直接整份发送拼版后的临时文件，不用再选“每张2版”。
多份处理：一份一份来，打完一套 A+B 再问要不要下一份。

用法：
  python3 duplex_print.py 文件.pdf
  python3 duplex_print.py 文件.pdf --dry-run        # 只显示拼版，不打印
  python3 duplex_print.py 文件.pdf -d Canon_E410_series
"""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

# A4 横向（pt）：297mm x 210mm
LAND_W, LAND_H = 842.0, 595.0

# 边距设置（照搬 ~/.local/bin/print_pdf.sh，针对 Linux 驱动反转问题：
# Top=47 约1.7cm，Left/Right/Bottom=10）
LP_MARGINS = [
    "-o", "media=A4",
    "-o", "fit-to-page",
    "-o", "landscape",
    "-o", "page-left=10",
    "-o", "page-right=10",
    "-o", "page-top=47",
    "-o", "page-bottom=10",
]


def split_pages(n: int):
    """按 4 页循环拆分：i%4==1/2 -> A，其余 -> B（1-indexed）。"""
    a, b = [], []
    for i in range(1, n + 1):
        if i % 4 in (1, 2):
            a.append(i)
        else:
            b.append(i)
    return a, b


def to_pairs(pages: list[int]):
    """[1,2,5,6,9] -> [(1,2),(5,6),(9,None)]，每对拼成一张横向 A4。"""
    pairs = []
    for i in range(0, len(pages), 2):
        left = pages[i]
        right = pages[i + 1] if i + 1 < len(pages) else None
        pairs.append((left, right))
    return pairs


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


def build_imposed(reader, pairs, out_path: Path):
    """把每对原页拼成一张 A4 横向。None 表示该半边留空。"""
    from pypdf import PageObject, Transformation

    from pypdf import PdfWriter
    writer = PdfWriter()
    half_w = LAND_W / 2
    for left, right in pairs:
        sheet = PageObject.create_blank_page(None, LAND_W, LAND_H)
        for idx, pageno in enumerate((left, right)):
            if pageno is None:
                continue
            src = reader.pages[pageno - 1]
            sw = float(src.mediabox.width)
            sh = float(src.mediabox.height)
            s = min(half_w / sw, LAND_H / sh)
            tx = idx * half_w + (half_w - sw * s) / 2
            ty = (LAND_H - sh * s) / 2
            op = Transformation().scale(s, s).translate(tx, ty)
            sheet.merge_transformed_page(src, op)
        writer.add_page(sheet)
    with open(out_path, "wb") as f:
        writer.write(f)


def run_lp_file(pdf_file: Path, printer: str | None) -> int:
    cmd = ["lp"]
    if printer:
        cmd += ["-d", printer]
    cmd += LP_MARGINS + [str(pdf_file)]
    print(f"$ {' '.join(cmd)}")
    r = subprocess.run(cmd, capture_output=True, text=True)
    print(r.stdout.strip())
    if r.returncode != 0:
        print(r.stderr.strip(), file=sys.stderr)
    return r.returncode


def main():
    ap = argparse.ArgumentParser(description="双面翻纸打印：A4横向拼版，一面两页，打完A翻纸打B")
    ap.add_argument("pdf", nargs="?", default=None, help="PDF 文件路径（不给则运行时询问）")
    ap.add_argument("-d", "--printer", default=None, help="打印机名（默认系统默认打印机）")
    ap.add_argument("--dry-run", action="store_true", help="只显示拼版，不实际打印")
    ap.add_argument("--yes", action="store_true", help="全程不询问（A->B、下一份都自动继续）")
    ap.add_argument("--keep", action="store_true", help="保留 /tmp 下的拼版临时文件（默认打完删除）")
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
        n = len(reader.pages)
    except Exception as e:
        print(f"读取 PDF 失败：{e}", file=sys.stderr)
        sys.exit(1)
    if n == 0:
        print("PDF 页数为 0，无需打印。")
        sys.exit(0)

    a, b = split_pages(n)
    a_pairs = to_pairs(a)
    b_pairs = to_pairs(b)
    # B 面补空白对齐 A 面张数，保证翻纸不错位
    while len(b_pairs) < len(a_pairs):
        b_pairs.append((None, None))
    sheets = len(a_pairs)

    print(f"文件：{pdf}\n总页数：{n}，A4横向拼版最少需要 {sheets} 张纸（单面一版、双面即正反）")
    print(f"A面原稿（{len(a)}页）：{compress(a)}")
    print(f"B面原稿（{len(b)}页）：{compress(b)}")
    print("拼版预览（每张 = 左|右）：")
    for i, (pa, pb) in enumerate(zip(a_pairs, b_pairs), 1):
        fa = f"{pa[0]}|{pa[1] if pa[1] else '空'}"
        fb = f"{pb[0] if pb[0] else '空'}|{pb[1] if pb[1] else '空'}"
        print(f"  第{i}张：A面[{fa}]  B面[{fb}]")

    if args.dry_run:
        print("[dry-run] 未拼版、未打印。去掉 --dry-run 即真实打印。")
        return

    if not args.yes:
        ans = input(f"最少需要 {sheets} 张 A4 纸（横向），是否开始打印 A 面？回车开始，输入 n 取消：").strip().lower()
        if ans in ("n", "no", "q", "quit"):
            print("已取消打印。")
            return

    tmpdir = Path(tempfile.mkdtemp(prefix="duplex_"))
    a_file = tmpdir / f"{pdf.stem}_A横向.pdf"
    b_file = tmpdir / f"{pdf.stem}_B横向.pdf"
    build_imposed(reader, a_pairs, a_file)
    build_imposed(reader, b_pairs, b_file)
    print(f"已拼版：\n  A面 {len(a_pairs)} 页 -> {a_file}\n  B面 {len(b_pairs)} 页 -> {b_file}")
    print("打印时按“实际大小 / 100% / A4横向”即可，不用再选每张多版。")

    try:
        copy_no = 1
        while True:
            print(f"\n===== 第 {copy_no} 份 =====")
            print(f"[1/2] 正在打印 A 面（{len(a_pairs)} 张）…")
            if run_lp_file(a_file, args.printer) != 0:
                print("A 面发送失败，已中止。", file=sys.stderr)
                sys.exit(1)

            if not args.yes:
                print("\nA 面已发送。请等 A 面打完，取出纸翻面放回（整叠一起翻）。")
                ans = input("回车继续打印 B 面，输入 n 取消本份：").strip().lower()
                if ans in ("n", "no", "q", "quit"):
                    print("已取消本份的 B 面。")
                    break

            print(f"\n[2/2] 正在打印 B 面（{len(b_pairs)} 张）…")
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
            print(f"拼版文件已保留在：{tmpdir}")


if __name__ == "__main__":
    main()
