# Lộ trình project Orange — từ LP đến bài chạy được

Đọc ngày 19/10/2026 từ tài liệu nằm trong submodule. Mốc tự đặt: thứ Sáu
23/10/2026. `project/readme` ghi hạn nộp Chủ nhật 25/10; ưu tiên hạn riêng
thầy đã thông báo cho bạn nếu khác. Đây là định hướng và môi trường khởi đầu,
chưa phải chương trình giải challenge.

## 1. Phạm vi thầy yêu cầu

- Báo cáo tối đa 10 trang: bối cảnh, mô hình (dữ liệu, biến, mục tiêu, ràng buộc),
  thực nghiệm và môi trường chạy.
- Bước 1–6: đọc dữ liệu, tính r, giải thời điểm 0, chưa có budget; giới hạn
  mỗi lần giải 1800 giây.
- Bước 7–9: dựng mạng ở thời điểm 1, tính lại r, thêm budget giữa 0 và 1;
  giới hạn 3600 giây. Bước 9 lại viết “only time period 0”, có vẻ là lỗi sao chép;
  cần xác nhận, không tự coi đây là yêu cầu chắc chắn.
- Bảng kết quả: số nút/cung/demand, objective, thời gian riêng `optimize!`,
  trạng thái, gap. Phần đầu README còn yêu cầu trung bình 10 lần chạy và số
  node branch-and-bound: đừng bỏ sót khi thống nhất phạm vi thực nghiệm.

## 2. Hiểu bài bằng ngôn ngữ đơn giản

Mạng gồm router (nút) và kết nối có hướng (cung). Mỗi cung có `metric` để tính
đường ngắn nhất và `capacity` để tính tải. Hai đại lượng này khác nhau.
Mỗi demand cần chuyển một lượng traffic từ nguồn đến đích.

Bạn chọn các trạm trung gian (waypoint) để tránh dồn traffic vào một kết nối.
Tuyến segment `<s,w,t>` có 2 segment `(s,w)` và `(w,t)`, 1 waypoint. Một segment
có thể đi qua nhiều cung vật lý. Giữa hai đầu segment, router tự dùng shortest
paths theo metric; bạn không tùy ý chọn từng cung của segment đó.

`r(i,j,a,t)` là phần của 1 đơn vị traffic từ i đến j chạy qua cung a ở thời điểm
t. Đây là hệ số tính trước, không phải biến mà solver chọn. Nếu r=0.5 và demand
có volume 100, segment đó đóng góp 50 đơn vị traffic lên cung a. Nếu capacity
là 200 thì đóng góp vào tải là 0.25 (25%). Tải tổng cộng cộng tất cả demand và
tất cả segment được dùng. Tải lớn hơn 1 được phép trong đề: đó là quá tải,
không tự thêm ràng buộc tải <= 1.

Thời điểm 1: một số cung bị tắt, volume đổi. Phải tính shortest paths và r lại.
Giữ nguyên waypoint vẫn có thể làm đường vật lý thay đổi mà không tốn budget.
Budget đếm số segment thêm/xóa, không đếm demand, không đếm cung vật lý.
Ví dụ `<s,w,t>` đổi thành `<s,t>` xóa 2 segment và thêm 1, tốn 3.

## 3. Ba điểm nên hỏi thầy sớm

1. **Cách tính r:** `calculating_r.pdf` dùng số shortest paths qua cung / tổng
   số shortest paths, tức chia đều theo đường hoàn chỉnh. Đề Orange mục 2 dùng
   ECMP: chia đều tại từng nút trên các cung đi tiếp về đích ngắn nhất.
   Hai cách không tương đương nói chung. Ví dụ s tách thành hai nhánh; nhánh
   thứ nhất có 1 đường đến đích, nhánh thứ hai tách tiếp thành 2 đường cùng độ
   dài. Chia đều theo đường cho 1/3,1/3,1/3; ECMP cho 1/2,1/4,1/4.
   Nếu làm theo tài liệu tính r của thầy, ghi rõ giả định trong báo cáo.
2. **Mục tiêu:** đề gốc tối ưu lexicographic vector tải đã sắp giảm dần. MLU
   chỉ tối ưu phần tử lớn nhất. Nên xin xác nhận có thể dùng MLU cho project
   hay phải triển khai đủ mục tiêu. Tổng tải hoặc trọng số tùy chọn không
   tự động tương đương lexicographic.
3. **Thực nghiệm:** xác nhận bước 9 là mô hình chung t=0,1, yêu cầu 10 lần chạy
   áp dụng ra sao cho instance lớn và có chấp nhận tập tuyến ứng viên không.

Có thể hỏi nguyên văn: “Em thấy calculating_r chia đều theo số đường ngắn nhất,
trong khi đề Orange chia ECMP tại mỗi nút. Em nên theo cách nào? Mục tiêu báo
cáo dùng min MLU được không hay cần lexicographic đầy đủ? Bước 9 là giải đồng
thời t=0,1 đúng không, và 10 runs có bắt buộc cho toàn bộ SetA không ạ?”

## 4. Mô hình khởi đầu ở t=0

Đây là mô hình **min MLU**, chưa giải đầy đủ mục tiêu lexicographic.

- `x[d,i,j]` nhị phân: demand d dùng segment từ i đến j; i khác j.
- `U >= 0`: mức tải lớn nhất.
- Mục tiêu: min U.
- Với mỗi demand và nút: tổng x đi ra trừ tổng x đi vào bằng 1 tại nguồn,
  -1 tại đích, 0 tại các nút còn lại (bảo toàn luồng).
- Với mỗi demand: tổng x <= max_segments.
- Với mỗi cung vật lý a:
  `sum(volume[d] * r[i,j,a] * x[d,i,j] for d,i,j) <= capacity[a] * U`.
- Segment không có đường đi phải bị cấm (`x=0` hoặc không tạo biến). Đặt r=0
  cho cặp không thể tới nhau mà vẫn cho x=1 sẽ tạo “đường đi miễn phí”.

Đây là MILP: giống LP với thêm biến nguyên/nhị phân. Không cần tự viết simplex
hay branch-and-bound. JuMP mô tả bài toán; HiGHS là solver giải bài toán.

Lưu ý: chỉ bảo toàn luồng + biến nhị phân chưa loại hết chu trình rời. Ở t=0,
có thể bỏ chu trình để không tăng tải và số segment. Khi có budget giữa các
thời điểm, không tùy tiện bỏ chu trình độc lập vì có thể đổi chi phí thay đổi.
Muốn nghiệm thực sự là tuyến, dùng ràng buộc loại chu trình, mô hình theo vị trí
segment hoặc tập tuyến ứng viên đơn; luôn kiểm tra tuyến sau khi giải.

Mở rộng t=0,1: thêm chỉ số thời gian. Đặt biến z không âm cho mỗi (d,i,j):
`z >= x[d,i,j,1]-x[d,i,j,0]` và `z >= x[d,i,j,0]-x[d,i,j,1]`, rồi
`sum(z) <= budget[1]`. Như vậy tuyến tính hóa giới hạn tổng trị tuyệt đối.
Giải chung hai thời điểm; cố định nghiệm tối ưu riêng t=0 trước khi giải t=1
là một heuristic, không đảm bảo tối ưu cho mô hình chung.

## 5. SetA thực tế và chiến lược tính toán

Đã đọc cả 20 bộ JSON: tất cả có 2 thời điểm, max_segments=6, không có cung song
song. Dùng `json_to_graph_pluto_v2.jl` làm tài liệu đọc dữ liệu phù hợp hơn bản
multigraph (bản đó yêu cầu multigraph=true).

| Instance | Nút | Cung | Demand | Số x ở một thời điểm: D*n*(n-1) |
|---|---:|---:|---:|---:|
| setA-01 | 20 | 80 | 40 | 15,200 |
| setA-02 | 30 | 150 | 45 | 39,150 |
| setA-03 | 50 | 250 | 20 | 49,000 |
| setA-04 | 50 | 250 | 200 | 490,000 |
| setA-20 | 400 | 2,000 | 6,000 | 957,600,000 |

Làm đúng và kiểm chứng trên 01 trước, rồi 02–03. Không dựng ngay mô hình đầy
đủ cho 20: riêng số biến đã quá lớn đối với cách triển khai thông thường trên
laptop. Giới hạn thời gian solver không giới hạn thời gian/bộ nhớ dựng mô hình.

Cho bộ lớn, hướng dự phòng thực dụng là tập tuyến ứng viên: mỗi demand có tuyến
trực tiếp và một số tuyến qua waypoint; tính trước tải của mỗi tuyến, chọn
một tuyến bằng biến nhị phân. Bắt đầu bằng các tuyến có <=1 waypoint, sau đó
thêm tuyến nếu cần. Đây là giới hạn không gian nghiệm (đề cho đến 6 segment),
nên optimum/gap solver chỉ chứng nhận cho mô hình ứng viên, không cho bài gốc.
Không cần học column generation để bắt đầu; chỉ triển khai nếu còn thời gian.

Baseline: mọi demand dùng `<s,t>` nếu s đến được t. Đây là tuyến 1 segment,
không phải không có segment. Nếu làm hai thời điểm, cùng tuyến segment trực
tiếp ở cả hai t có chi phí đổi bằng 0, miễn là còn đường đi ở mỗi thời điểm.
Tính baseline trước solver để có giá trị đối chiếu và nghiệm khởi tạo.

## 6. Học đúng phần đang cần

Thứ tự học và làm: (1) Julia đủ đọc JSON và vòng lặp; (2) graph có hướng,
shortest paths, ECMP/r; (3) biến nhị phân, bảo toàn luồng; (4) JuMP;
(5) incumbent, lower bound và gap; (6) tuyến tính hóa trị tuyệt đối.

Đọc bài Julia/JuMP trong lecture3 khi viết mô hình; lecture4–5 khi cần hiểu
MILP và branch-and-bound. Chưa cần học hết tối ưu phi tuyến, chứng minh simplex,
duality nâng cao, tự viết solver, VRP hay column generation.

Với bài min: nghiệm khả thi đang có là upper bound UB; solver cung cấp lower
bound LB. Theo README: gap = 1 - LB/UB nếu UB > 0 và có nghiệm. Không có
incumbent thì ghi NA, không gọi time limit là infeasible. UB=0 cần xử lý riêng.
LP relaxation (thay x nhị phân bằng 0<=x<=1) cho một cận dưới nhưng nghiệm chia
lẻ không nhất thiết là tuyến segment hợp lệ.

## 7. Lịch đến thứ Sáu 23/10

| Ngày | Đầu ra cần có |
|---|---|
| Thứ Hai 19/10 | Môi trường chạy; đọc 01; hiểu demand/segment/r; gửi câu hỏi về r và mục tiêu |
| Thứ Ba 20/10 | Tính r; kiểm tra đồ thị nhỏ bằng tay; baseline 01; mô hình t=0 chạy được |
| Thứ Tư 21/10 | Chạy 01–03; kiểm tra nghiệm/tải độc lập; thêm t=1 và budget; bắt đầu viết báo cáo |
| Thứ Năm 22/10 | Chốt mô hình; chạy thực nghiệm theo phạm vi đã thống nhất; ghi giới hạn trên bộ lớn |
| Thứ Sáu 23/10 | Hoàn thiện bảng, giải thích kết quả, chạy lại từ môi trường sạch, chốt báo cáo <=10 trang |

Ưu tiên correctness và giải thích được từng ràng buộc. Nếu chậm, có baseline +
mô hình t=0 đúng + kết quả nhỏ trước, rồi hoàn thành phần t=1; phần còn thiếu
phải ghi rõ, không xem đó là đã đáp ứng trọn yêu cầu.

20 bộ * 10 lần * 1800 giây = tối đa 100 giờ solver cho t=0; thêm thí nghiệm
3600 giây là tối đa 200 giờ nữa. Đây là ngân sách xấu nhất nếu mọi lần đều hết
time limit, chưa gồm dựng mô hình. Vì vậy phải làm rõ yêu cầu và chạy sớm.

## 8. Kiểm chứng và báo cáo

Trước thực nghiệm dài, kiểm tra r trên một đường duy nhất, một hình thoi và
ví dụ phân nhánh không cân để phân biệt ECMP/chia theo đường. Kiểm tra tổng
luồng đến đích bằng 1, không traffic trên cung tắt, bảo toàn luồng trung gian,
mapping JSON ID sang chỉ số Julia. `v[1]` của Julia là volume thời điểm 0.

Sau khi solver trả nghiệm: dựng lại tuyến, kiểm tra số segment, không có
chu trình, tính tải từ tuyến độc lập với biểu thức trong model, tính budget.
Không lấy objective của solver làm bằng chứng duy nhất rằng code đúng.

Bảng nên lưu từng run: instance, thời điểm, formulation, cách tính r,
nodes/arcs/demands, baseline, objective, bound, gap, thời gian optimize!,
termination/primal status, số node B&B, seed, threads và phiên bản solver.
Warm-up trước khi đo để hạn chế ảnh hưởng biên dịch Julia; vẫn ghi rõ cách đo.
Lưu cả raw results trước khi lấy trung bình; không gộp run không có nghiệm
thành objective bằng 0. Không cần chạy benchmark đầy đủ trong lúc học setup.

## 9. Môi trường Julia tại repo

`Project.toml` khai báo JuMP, HiGHS, JSON3, Graphs. `Manifest.toml` do Pkg tạo
ghi chính xác phiên bản phụ thuộc. Đây là môi trường project tương tự mục đích
của venv; Julia dùng chung cache package nên không cần sao chép interpreter.
Conda orange không cần cho chương trình Julia này.

Từ thư mục gốc:

```powershell
julia --project=. scripts/setup.jl
julia --project=. scripts/check_setup.jl
julia --project=.
```

Nếu terminal chưa nhận `julia`, bản tìm thấy trên máy là:

```powershell
& 'C:\Users\admin\.julia\juliaup\julia-1.13.1+0.x64.w64.mingw32\bin\julia.exe' --project=. scripts/check_setup.jl
```

Trong REPL đang mở, có thể dùng `import Pkg; Pkg.activate(".")` từ thư mục repo.
`check_setup.jl` giải một bài nguyên cực nhỏ và đọc thống kê cả 20 bộ; nó chưa
giải bài Orange. Giữ code của bạn ngoài submodule để dễ quản lý và nộp lại.

Tài liệu chính thức:
- https://pkgdocs.julialang.org/v1/environments/
- https://jump.dev/JuMP.jl/stable/installation/

Tài liệu nguồn trong repo: `project/readme`, `Challenge_Orange_ROADEF_2026_Subject.pdf`
(mục 2, 3, 5), `calculating_r.pdf`, hai notebook chuyển JSON thành graph.
