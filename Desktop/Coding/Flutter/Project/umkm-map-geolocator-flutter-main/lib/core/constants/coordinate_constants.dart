class CoordinateConstants {
  final int no;
  final String nama;
  final String produk;
  final String noKontak;
  final double latitude;
  final double longitude;
  final String imageUrl;

  CoordinateConstants({
    required this.no,
    required this.nama,
    required this.produk,
    required this.noKontak,
    required this.latitude,
    required this.longitude,
    this.imageUrl = 'https://picsum.photos/200',
  });
}

final List<CoordinateConstants> coordinateData = [
  CoordinateConstants(
    no: 1,
    nama: 'Saltin Snack Indonesia',
    produk: 'Kerupuk Kulit Ikan',
    noKontak: '0877-7789-7890',
    latitude: -6.974013,
    longitude: 109.121882,
  ),
  CoordinateConstants(
    no: 2,
    nama: 'Arumi Kita',
    produk: 'Makanan Ringan, Mie Lidi',
    noKontak: '0856-4227-0700',
    latitude: -6.99172,
    longitude: 109.123829,
  ),
  CoordinateConstants(
    no: 3,
    nama: 'Paklin Indonesia',
    produk: 'Donat Kentang Beragam Rasa',
    noKontak: '',
    latitude: -6.884746,
    longitude: 109.13774,
  ),
  CoordinateConstants(
    no: 4,
    nama: 'Yukopan Bakery',
    produk: 'Roti Jepang',
    noKontak: '0821-3579-4279',
    latitude: -6.980042,
    longitude: 109.127987,
  ),
  CoordinateConstants(
    no: 5,
    nama: 'Kedai SalamNyetil',
    produk: 'Makanan Olahan Ikan dan Udang',
    noKontak: '',
    latitude: -6.972359,
    longitude: 109.13434,
  ),
  CoordinateConstants(
    no: 6,
    nama: 'Cemil_Kecil',
    produk: 'Brownies, Cake dan Cemilan',
    noKontak: '0895-3791-80007',
    latitude: -6.975096,
    longitude: 109.121628,
  ),
];
